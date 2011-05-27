function s = hmax_uiuc_score(uiucPath, ss, locs)

% S = hmax_uiuc_score(UIUCPATH, SS, LOCS) returns the score for the UIUC car
% detection task.  Calls the UIUC scoring program.
%
% *** NOTE: this program has only been tested under Linux.
%
%    UIUCPATH - Path where the UIUC car dataset and scoring programs can be
%    found.
%
%    SS - True for the single-scale task, false for the multi-scale task.
%
%    LOCS - Detections.  Cell array of structs; see code.

%-----------------------------------------------------------------------------------------------------------------------

% Write detections to file.
inFilePath = tempname;
fid = fopen(inFilePath, 'w');
for i = 1 : numel(locs)
    fprintf(fid, '%u:', i - 1);
    for j = 1 : numel(locs{i}.y)
        if ss
            fprintf(fid, ' (%i,%i)', round(locs{i}.y(j)), round(locs{i}.x(j)));
        else
            fprintf(fid, ' (%i,%i,%i)', round(locs{i}.y(j)), round(locs{i}.x(j)), round(locs{i}.w(j)));
        end
    end        
    fprintf(fid, '\n');
end
fclose(fid);

% Run evaluation program.
if ss
    program      = 'Evaluator';
    trueFilePath = fullfile(uiucPath, 'trueLocations.txt');
else
    program      = 'Evaluator_Scale';
    trueFilePath = fullfile(uiucPath, 'trueLocations_Scale.txt');
end
outFilePath = tempname;
path = cd(uiucPath);
system(['java ' program ' ' trueFilePath ' ' inFilePath ' > ' outFilePath]);
cd(path);
delete(inFilePath);

% Read output file.
fid = fopen(outFilePath, 'r');
s.recall    = NaN;
s.precision = NaN;
s.fMeasure  = NaN;
while true
    line = fgetl(fid);
    if ~ischar(line), break; end
    s.recall    = GetNumber(s.recall   , line, 'Recall'   );
    s.precision = GetNumber(s.precision, line, 'Precision');
    s.fMeasure  = GetNumber(s.fMeasure , line, 'F-measure');
end
fclose(fid);
delete(outFilePath);

return;

%***********************************************************************************************************************

function number = GetNumber(number, line, word)

index = strfind(line, word);
if numel(index) ~= 1, return; end

string = '';

for i = index + numel(word) : numel(line)
    if line(i) == '%', break; end
    if isstrprop(line(i), 'digit') || (line(i) == '.'), string(end + 1) = line(i); end
end

value = str2double(string);
if ~isnan(value), number = value; end

return;