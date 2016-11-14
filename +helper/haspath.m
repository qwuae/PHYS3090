function r = haspath(Folder)
[Folder,~,~] = fileparts(Folder);
pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
  r = any(strcmpi(Folder, pathCell));
else
  r = any(strcmp(Folder, pathCell));
end
end