function results = searchModel(model,searchTerm,varargin)
% Search for the specified term in the given model.
% The performed search is fuzzy if similarity is lower than 1.
% 
% USAGE:
%    results = searchModel(model,searchTerm,...)
%
% INPUTS:
%    model:         The model to search in
%    searchTerm:    The term to search for
%    varargin:      Additional parameters as parameter/value pairs or value struct.
%                   Available parameters are:
%                    * printLevel - Whether to print the results or just return a search struct. (Default = true) .
%                    * similarity - Minimum similarity (as provided in calcSim) for matches.
%                    
% OUTPUTS:
%    results:       The results struct build as follows:
%                    * .field - a struct array either of the basic fields of the model (e.g. rxns, mets etc).
%                    * .field.id - The id of the matching element
%                    * .field.matches - information about the matches of the respective ID.
%                    * .field.matches.value - the value that matched.
%                    * .field.matches.source - the field that contained the matching value.
%
% .. Author: - Thomas Pfau, June 2018

parser = inputParser();
parser.addParameter('printLevel',1,@isnumeric);
parser.addParameter('similarity',0.8,@(x) isnumeric(x) && x <= 1 && x >= 0);
parser.parse(varargin{:});
similarity = parser.Results.similarity;
printLevel = parser.Results.printLevel;

%First collect some potential fields, which are known.
baseFields = {'rxns','mets','vars','ctrs','genes','comps','prots'};
baseFieldNames = {'reactions', 'metabolites', 'variables', 'constraints', 'genes', 'compartments', 'proteins'};
nameFields = regexprep(baseFields,'s$','Names');
knownFields = union(baseFields,nameFields);
dbFields = getDefinedFieldProperties('DataBaseFields',true);
knownFields = union(knownFields,dbFields(:,3));
%And get the annotations which can also be looked up.
annotationQualifiers = getBioQualifiers();
results = struct();
%Now, loop over all basic fields 
for field = 1:numel(baseFields)
    cField = baseFields{field};
    if ~isfield(model,cField)
        continue;
    end    
    %Get the model fields associated with this type.
    modelFields = getModelFieldsForType(model,cField);
    resultList = cell(numel(model.(cField)),numel(modelFields));    
    similarities = zeros(numel(model.(cField)),1);
    for aqual = 1:numel(annotationQualifiers)  
       cAnnotType = regexprep(cField,'s$',annotationQualifiers{aqual});
       annotationsFields = modelFields(cellfun(@(x) strncmp(x,cAnnotType,length(cAnnotType)),modelFields));
    end
    %Except for xyzNames there are few other fields which contain sensibly
    %searchable information (subSystems is one example). 
    for modelField = 1:numel(modelFields)        
        cModelField = modelFields{modelField};
        if strcmp(cModelField,'subSystems')
            %SubSystems is special, as it contains cell arrays.
            fieldToUse = cellfun(@(x) strjoin(x,';'),model.subSystems,'Uniform',0);
            isAnnotation = true;
            
        elseif any(strcmp(cModelField,knownFields))
            %If its a known field, than it is a cell array of strings and
            %we will use it accordingly
            isAnnotation = false;
            if strcmp(cModelField,'mets')
                if isempty(regexp(searchTerm,'\[[^\[]\]$'))
                    fieldToUse = regexprep(model.mets,'\[[^\[]\]$','');
                else
                    fieldToUse = model.mets;
                end
            else
                fieldToUse = model.(cModelField);
            end
        else      
            if any(strcmp(cModelField,annotationsFields))
                %If its an annotation field, we look into it.
                fieldToUse = model.(cModelField);
                isAnnotation = true;
            else
                %Field does nto match anything. don't search in it.
                continue 
            end
        end        
        %Find matches
        [matchingIDs,positions,csims] = findMatchingFieldEntries(fieldToUse,searchTerm,isAnnotation,similarity);
        if ~isempty(positions)
            resultList(positions,modelField) = matchingIDs;            
            similarities(positions) = max(similarities(positions),csims);
        end
    end
    if any(any(~cellfun(@isempty, resultList)))
        if printLevel > 0            
            fprintf('The following %s have matching properties:\n',baseFieldNames{field});            
        end
        %get the base field
        results.(cField) = struct();
        relRows = ~all(cellfun(@isempty,resultList),2);
        results.(cField).id = 'start';        
        results.(cField).matches = struct();
        results.(cField)(sum(relRows)).id = 'end';
        %And the relevant results for that base field
        relResults = resultList(relRows,:);
        relResultPos = find(relRows);
        %ORder according to highest similarity
        [~,simorder] = sort(similarities(relRows),'descend');
        for cResults = 1:size(relResults,1)
            results.(cField)(cResults).id = model.(cField){relResultPos(simorder(cResults))};            
            results.(cField)(cResults).matches = struct();
            %Init struct with size
            results.(cField)(cResults).matches.source = '';
            results.(cField)(cResults).matches.value = '';
            %get the field which have matching entries.
            resultEntries = find(~cellfun(@isempty, relResults(simorder(cResults),:)));
            results.(cField)(cResults).matches(numel(resultEntries)).source = '';
            for cResult = 1:numel(resultEntries)
                %Set the source to the fieldName and the value to the found
                %value.
                results.(cField)(cResults).matches(cResult).source = modelFields{resultEntries(cResult)};
                results.(cField)(cResults).matches(cResult).value = relResults{simorder(cResults),resultEntries(cResult)};
            end
            if printLevel > 0   
                %Print the individual ids and fields the similarity was
                %achieved on
                fprintf('ID: %s ', model.(cField){relResultPos(simorder(cResults))});                
                matchingFields = {results.(cField)(cResults).matches(:).source};
                matchingValues = {results.(cField)(cResults).matches(:).value};
                %filter ID Field
                idpos = strcmp(matchingFields,cField);
                matchingFields = matchingFields(~idpos);
                matchingValues = matchingValues(~idpos);
                if ~isempty(matchingFields)
                   fprintf('with the following matching values:\n');
                   matches = strcat(matchingFields,{': '},matchingValues);
                   fprintf('%s', strjoin(matches,'; '));
                end
                fprintf('\n\n');
            end
        end
    end 
end
         
        


