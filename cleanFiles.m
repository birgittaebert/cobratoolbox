% Clear previous log files in logFiles/
D = dir('logFiles/*.log');
nbFiles = numel(D);
if(nbFiles > 0)
    fprintf('\n There are %d files in logFiles/\n', nbFiles);
    m=input('\n Do you want to clean all log files in logFiles/ ? - Y/N [Y]:','s');
    if m=='Y' || m =='y'
      unix('sudo rm logFiles/*.log');
      fprintf(' >> All log files in logFiles/ removed.\n');
    end
else
    fprintf('\n The directory logFiles/ is empty.\n');
end

% Clear previous result files in results/
D = dir('results/*.mat');
nbFiles = numel(D);
if(nbFiles > 0)
    fprintf('\n There are %d files in results/\n', nbFiles);
    m=input('\n Do you want to clean al results files in results/ ? - Y/N [Y]:','s');
    if m=='Y' || m =='y'
      unix('sudo rm results/*.mat');
      fprintf(' >> All result files in results/ removed.\n');
    end
else
    fprintf('\n The directory results/ is empty.\n');
end
