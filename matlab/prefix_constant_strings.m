function replacements = prefix_constant_strings(modelFile)
%PREFIX_CONSTANT_STRINGS Constantブロックの値に "MConst." プレフィックスを追加し、別名で保存します。
%   ... (ヘルプテキストは省略) ...

    arguments
        modelFile (1, 1) string
    end

    validateattributes(modelFile, {"string", "char"}, {"nonempty", "scalartext"});
    if ~isfile(modelFile)
        error("prefix_constant_strings:FileNotFound", ...
            "The specified model file does not exist: %s", modelFile);
    end

    % 【変更点1】 ディレクトリパス(fileDir)も取得するように変更
    [fileDir, modelName, ext] = fileparts(modelFile);
    
    if ~strcmpi(ext, ".slx")
        error("prefix_constant_strings:InvalidExtension", ...
            "Model file must be a .slx file: %s", modelFile);
    end

    load_system(modelFile);
    cleanupObj = onCleanup(@() close_system(modelName, 0)); %#ok<NASGU>

    constBlocks = find_system(modelName, ...
        "BlockType", "Constant", ...
        "FollowLinks", "on", ...
        "LookUnderMasks", "all", ...
        "SearchDepth", 10);

    replacements = struct("Block", {}, "OriginalValue", {}, "UpdatedValue", {});
    for idx = 1:numel(constBlocks)
        blockPath = constBlocks{idx};
        value = get_param(blockPath, "Value");
        trimmedValue = strtrim(value);

        if isempty(trimmedValue) || startsWith(trimmedValue, "MConst.") || isNumericLiteral(trimmedValue)
            continue;
        end

        newValue = "MConst." + trimmedValue;
        set_param(blockPath, "Value", newValue);

        replacements(end + 1) = struct( ...
            "Block", blockPath, ...
            "OriginalValue", value, ...
            "UpdatedValue", char(newValue)); %#ok<AGROW>
    end

    % 【変更点2】 新しいファイルパスを作成 ("MConst_" を付与)
    % fullfileを使うことで、元のファイルと同じフォルダにパスを通します
    newModelFile = fullfile(fileDir, "MConst_" + modelName + ext);

    % 【変更点3】 第2引数に新しいファイルパスを指定して保存（別名保存）
    save_system(modelName, newModelFile);
    
    % 保存したのでメモリ上のモデルを閉じる
    close_system(modelName, 0);
    cleanupObj = []; %#ok<NASGU>
    
    % 完了メッセージ（オプション）
    fprintf('保存完了: %s\n', newModelFile);
end

function tf = isNumericLiteral(expr)
    numericValue = str2double(expr);
    tf = ~isnan(numericValue);
end