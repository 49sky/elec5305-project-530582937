function validate_source_split(split)
allPaths = strings(0,1);
for source = ["speech","music"]
    for partition = ["train","validation","test"]
        paths = string(split.(source).(partition)(:));
        if any(ismissing(paths) | strlength(paths) == 0)
            error("presence:InvalidSplit","Source paths must be nonempty.");
        end
        for k = 1:numel(paths)
            [ok,attributes] = fileattrib(paths(k));
            if ~ok
                error("presence:MissingSource","Cannot find source: %s",paths(k));
            end
            paths(k) = string(attributes.Name);
        end
        allPaths = [allPaths; paths];
    end
end
if numel(unique(allPaths)) ~= numel(allPaths)
    error("presence:SourceLeakage","A source occurs more than once in the source split.");
end
end
