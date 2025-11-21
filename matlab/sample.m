function replacements = prefix_constant_strings(modelFile)
%PREFIX_CONSTANT_STRINGS Constantブロックの値に "MConst." プレフィックスを追加する関数
%   REPLACEMENTS = PREFIX_CONSTANT_STRINGS(MODELFILE) は指定されたSimulinkモデル(.slx)を読み込み、
%   最大10階層の深さまでConstantブロックを検索します。
%   数値以外の値を持つConstantブロックに対し、値の先頭に "MConst." を追加します。
%   すでに "MConst." で始まっている場合や、値が数値リテラルの場合は変更しません。
%   変更後、元のファイル名の先頭に "MConst_" を付与した名前で別保存し、
%   変更内容のリスト（構造体配列）を返します。
%
%   返却される構造体のフィールド:
%     Block         - 更新されたConstantブロックのフルパス
%     OriginalValue - 変更前の値
%     UpdatedValue  - プレフィックス適用後の新しい値

    arguments
        modelFile (1, 1) string % 入力はスカラーの文字列であることを定義
    end

    % 入力が文字列であり、空でないことを確認
    validateattributes(modelFile, {"string", "char"}, {"nonempty", "scalartext"});
    
    % 指定されたファイルが存在するか確認
    if ~isfile(modelFile)
        error("prefix_constant_strings:FileNotFound", ...
            "The specified model file does not exist: %s", modelFile);
    end

    % パス、ファイル名、拡張子に分解
    [modelFolder, modelName, ext] = fileparts(modelFile);
    
    % 拡張子が .slx であるかを確認
    if ~strcmpi(ext, ".slx")
        error("prefix_constant_strings:InvalidExtension", ...
            "Model file must be a .slx file: %s", modelFile);
    end

    % 保存用の新しいファイル名を作成（例: model.slx -> MConst_model.slx）
    newModelName = "MConst_" + modelName;
    newModelFile = fullfile(modelFolder, newModelName + ext);

    % モデルをロード（メモリ上に展開）
    load_system(modelFile);
    
    % onCleanup: この関数を抜ける際（エラー時含む）に、確実にモデルを閉じるための処理を登録
    % 元のモデル名と新しいモデル名の両方を閉じる対象とする
    cleanupObj = onCleanup(@() closeModels({modelName, newModelName})); %#ok<NASGU>

    % 指定条件に一致するConstantブロックを検索
    constBlocks = find_system(modelName, ...
        "BlockType", "Constant", ... % Constantブロックのみ対象
        "FollowLinks", "on", ...     % ライブラリリンク先も検索対象
        "LookUnderMasks", "all", ... % マスク内部も検索
        "SearchDepth", 10);          % 検索の深さは10階層まで

    % 置換ログ用の構造体を初期化
    replacements = struct("Block", {}, "OriginalValue", {}, "UpdatedValue", {});
    
    % 検索された各ブロックに対して処理を実行
    for idx = 1:numel(constBlocks)
        blockPath = constBlocks{idx};
        value = get_param(blockPath, "Value"); % 現在の設定値を取得
        trimmedValue = strtrim(value);         % 前後の空白を除去

        % 値が空の場合はスキップ
        if isempty(trimmedValue)
            continue;
        end

        % すでに "MConst." が付いている場合はスキップ（二重付与防止）
        if startsWith(trimmedValue, "MConst.")
            continue;
        end

        % 値が数値リテラル（"10" や "3.14" など）の場合はスキップ
        if isNumericLiteral(trimmedValue)
            continue;
        end

        % 新しい値を作成（"MConst." + 元の値）
        newValue = "MConst." + trimmedValue;
        
        % ブロックのパラメータを更新
        set_param(blockPath, "Value", newValue);

        % 変更内容をログに追加
        replacements(end + 1) = struct( ...
            "Block", blockPath, ...
            "OriginalValue", value, ...
            "UpdatedValue", char(newValue)); %#ok<AGROW>
    end

    % 変更を反映したモデルを新しいファイル名で保存
    % save_system(ロード中のモデル名, 保存先のパス)
    save_system(modelName, newModelFile);
    
    % cleanupObjをクリアして、ここで明示的に closeModels を実行させる
    cleanupObj = []; %#ok<NASGU>
end

function tf = isNumericLiteral(expr)
%ISNUMERICLITERAL 文字列が数値リテラルであるか判定するヘルパー関数
    numericValue = str2double(expr);
    % NaNでなければ数値として変換できたことを意味する
    tf = ~isnan(numericValue);
end

function closeModels(modelNames)
%CLOSEMODELS ロードされているモデルを閉じるヘルパー関数
    for nameCell = modelNames
        name = nameCell{1};
        try %#ok<TRYNC>
            % モデルがメモリ上にロードされている場合のみ閉じる
            if bdIsLoaded(name)
                close_system(name, 0); % 0 = 変更を保存せずに閉じる（すでにsave_system済みのため）
            end
        end
    end
end