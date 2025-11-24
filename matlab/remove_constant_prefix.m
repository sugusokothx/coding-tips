function replacements = remove_constant_prefix(modelFile)
%REMOVE_CONSTANT_PREFIX Constantブロックの値から "MConst." プレフィックスを削除する関数
%   REPLACEMENTS = REMOVE_CONSTANT_PREFIX(MODELFILE) は指定されたSimulinkモデル(.slx)を読み込み、
%   最大10階層の深さまでConstantブロックを検索します。
%   値が "MConst." で始まるConstantブロックに対し、そのプレフィックスを削除します。
%   （例: "MConst.MPOLE" -> "MPOLE"）
%
%   変更後、元のファイル名の先頭に "Reverted_" を付与した名前で別保存し、
%   変更内容のリスト（構造体配列）を返します。
%
%   返却される構造体のフィールド:
%     Block         - 更新されたConstantブロックのフルパス
%     OriginalValue - 変更前の値（MConst.付き）
%     UpdatedValue  - 削除後の新しい値

    arguments
        modelFile (1, 1) string
    end

    % --- バリデーション（入力チェック） ---
    validateattributes(modelFile, {"string", "char"}, {"nonempty", "scalartext"});
    if ~isfile(modelFile)
        error("remove_constant_prefix:FileNotFound", ...
            "The specified model file does not exist: %s", modelFile);
    end

    [modelFolder, modelName, ext] = fileparts(modelFile);
    if ~strcmpi(ext, ".slx")
        error("remove_constant_prefix:InvalidExtension", ...
            "Model file must be a .slx file: %s", modelFile);
    end

    % 保存用の新しいファイル名（例: Reverted_MConst_model.slx）
    % 元ファイルを上書きしないよう "Reverted_" を付与します
    newModelName = "Reverted_" + modelName;
    newModelFile = fullfile(modelFolder, newModelName + ext);

    % --- モデルのロードと後処理 ---
    load_system(modelFile);
    % 関数終了時にモデルを確実に閉じるための処理
    cleanupObj = onCleanup(@() closeModels({modelName, newModelName})); %#ok<NASGU>

    % --- Constantブロックの検索 ---
    constBlocks = find_system(modelName, ...
        "BlockType", "Constant", ...
        "FollowLinks", "on", ...
        "LookUnderMasks", "all", ...
        "SearchDepth", 10);

    % --- 置換処理 ---
    replacements = struct("Block", {}, "OriginalValue", {}, "UpdatedValue", {});
    
    for idx = 1:numel(constBlocks)
        blockPath = constBlocks{idx};
        value = get_param(blockPath, "Value");
        trimmedValue = strtrim(value);

        % 値が空の場合はスキップ
        if isempty(trimmedValue)
            continue;
        end

        % "MConst." で始まっているか確認
        if startsWith(trimmedValue, "MConst.")
            % "MConst." の直後にある文字列を抽出（これが元の変数名になる）
            newValue = extractAfter(trimmedValue, "MConst.");
            
            % ブロックの値を更新
            set_param(blockPath, "Value", newValue);

            % ログに追加
            replacements(end + 1) = struct( ...
                "Block", blockPath, ...
                "OriginalValue", value, ...
                "UpdatedValue", char(newValue)); %#ok<AGROW>
        end
        % "MConst." で始まっていないものは、数値であれ変数であれ無視します
    end

    % --- 保存 ---
    save_system(modelName, newModelFile);
    cleanupObj = []; %#ok<NASGU>
end

function closeModels(modelNames)
%CLOSEMODELS ロードされているモデルを閉じるヘルパー関数
    for nameCell = modelNames
        name = nameCell{1};
        try %#ok<TRYNC>
            if bdIsLoaded(name)
                close_system(name, 0);
            end
        end
    end
end