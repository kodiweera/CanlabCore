function [stats hh hhfill table_group multcomp_group] = image_similarity_plot(obj, varargin)
% Point-biserial correlations between images in fmri_data obj and set of
% 'spatial basis function' images (e.g., 'signatures' or pre-defined maps)
%
% Usage:
% ::
%
%    stats = image_similarity_plot(obj, 'average');
%
% This is a method for an image_vector object
%
% ..
%     Author and copyright information:
%
%     Copyright (C) 2015 Tor Wager
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
% ..
%
% :Inputs:
%
%   **obj:**
%        An image object with one or more images loaded
%
% :Optional inputs:
%
%   **average:**
%        Calculate average over images in obj with standard errors
%        Useful if obj contains one image per subject and you want
%        to test similarity with maps statistically.
%        Default behavior is to plot each individual image.
%
%   **bucknerlab**
%        Use 7 network parcellation from Yeo et al. as basis for
%        comparisons
%
%   **kragelemotion**
%        Use 7 emotion-predictive models from Kragel & LaBar 2015 for
%        basis of comparisons
%
% 	**compareGroups**
%        Perform multiple one-way ANOVAs with group as a factor (one for
%        each spatial basis); requires group as subsequent input
%
%   **group**
%        Indicates group membership for each image
%
%   **noplot**
%        Omits plot (print stats only)
%
%
% :Outputs:
%
%   **stats:**
%        Structure including:
%           - .r, Correlations in [7 networks x images in obj] matrix
%           - .t, T-test (if 'average' is specified)
%           - .line_handles Handles to polar plot lines so you can
%             customize
%           - .fill_handles Handles to polar plot fills so you can
%             customize
%           - .table_spatial, ANOVA table with subject as row factor and
%             spatial basis as column factor (one way repeated measures
%             ANOVA, requires 'average' to be specified)
%           - .multcomp_spatial, multiple comparisons of means across
%             different spatial bases, critical value determined
%             by Tukey-Kramer method (see multcompare)
%   **table_group**
%             multiple one-way ANOVA tables (one for each
%             spatial basis) with group as column factor (requires
%             'average' to be specified)
%   **multcomp_group**
%             mutiple comparisons of means across groups, one output
%             cell for each spatial basis, critical value determined
%             by Tukey-Kramer method (see multcompare)
%
% :Examples:
% ::
%
%    % corrdat is an fmri_data object with 18 images from searchlight
%    % correlation in it.  Then:
%    stats = image_similarity_plot_bucknermaps(corrdat, 'average');
%
%    % t_diff is a thresholded statistic_image object
%    stats = image_similarity_plot_bucknermaps(t_diff);
%
% :See also:
%
% tor_polar_plot
%
% ..
%    Programmers' notes:
%    List dates and changes here, and author of changes
% List dates and changes here, and author of changes
% 11/30/2015 (Phil Kragel)
%   -   added anova (rm) comparing means across spatial bases
%   -   added anova (1-way) comparing means across groups for each spatial
%       basis (e.g., for each buckner network)
% 12/15/2015 (Phil Kragel)
%   - added option to omit plotting
%
% ..

% ..
% DEFAULTS AND INPUTS
% ..

doaverage = 0; % initalize optional variables to default values here.
mapset = 'npsplus';  % 'bucknerlab'
table_group={}; %initialize output
multcomp_group={}; %initialize output
noplot=false;
% optional inputs with default values
% -----------------------------------

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            
            case 'average', doaverage = 1;
                
            case {'bucknerlab', 'kragelemotion'}
                mapset = varargin{i};
                
            case 'mapset'
                mapset = 'custom';
                mask = vararagin{i + 1}; varargin{i + 1} = [];
                
                %case 'basistype', basistype = varargin{i+1}; varargin{i+1} = [];
            case 'compareGroups'
                compareGroups = true;
                group = varargin{i+1};
                
            case 'noplot'; noplot=true;
                
            otherwise, warning(['Unknown input string option:' varargin{i}]);
        end
    end
end


switch mapset
    
    case 'bucknerlab'
        [mask, networknames] = load_bucknerlab_maps;
        networknames=networknames';
    case 'npsplus'
        [mask, networknames] = load_npsplus;
        
    case 'kragelemotion'
        [mask, networknames] = load_kragelemotion;
        
    case 'custom'
        
    otherwise
        error('unknown map set');
        
        
end



% Deal with space and empty voxels so they line up
% ------------------------------------------------------------------------

mask = replace_empty(mask); % add zeros back in

mask = resample_space(mask, obj);

obj = replace_empty(obj);

% Correlation
% ------------------------------------------------------------------------

% Point-biserial correlation is same as Pearson's r.
% Gene V. Glass and Kenneth D. Hopkins (1995). Statistical Methods in Education and Psychology (3rd edition ed.). Allyn & Bacon. ISBN 0-205-14212-5.
% Linacre, John (2008). "The Expected Value of a Point-Biserial (or Similar) Correlation". Rasch Measurement Transactions 22 (1): 1154.
% http://www.andrews.edu/~calkins/math/edrm611/edrm13.htm#POINTB

% If both binomial, could use Dice coeff:
%dice_coeff = dice_coeff_image(mask);

% if map or series of maps, point-biserial is better.

% This is done for n images in obj

r = corr(double(obj.dat), double(mask.dat))';

stats.r = r;

if ~doaverage
    
    if ~noplot
        % Plot values for each image in obj
        [hh, hhfill] = tor_polar_plot({r}, scn_standard_colors(size(r, 2)), {networknames}, 'nonneg');
    end
    
elseif doaverage
    
    z=fisherz(r'); %transform values
    
    
    if exist('compareGroups','var') %if we want to do analysis for multiple groups
        
        groupValues=unique(group);
        g=num2cell(groupValues); %create cell array of group numbers
        
        
        for i=1:size(z,2) %for each spatial basis do an anova across groups
            [p table_group{i} st]=anova1(z(:,i),group,'off'); %get anova table
            [c,~] = multcompare(st,'Display','off'); %perform multiple comparisons
            multcomp_group{i}=[g(c(:,1)), g(c(:,2)), num2cell(c(:,3:6))]; %format table for output
            
        end
        
        
    for i=1:size(z,2)
        disp(['Between-group comparisons for ' networknames{i} ':']);
        disp('--------------------------------------');
        disp(['One-way ANOVA: F(' num2str(table_group{i}{2,3}) ','  num2str(table_group{i}{3,3}) ') = ' num2str(table_group{i}{2,5},3) ', P = ' num2str(table_group{i}{2,6},3)])
        disp(' ')
        disp('Multiple comparisons of means:')
        disp(' ');
        print_matrix(cell2mat(multcomp_group{i}), {'Group 1' 'Group 2' 'LCI' 'Estimate' 'UCI' 'P'});
        disp(' ');
    end
    
        
        
    else
        group=ones(size(r,2),1); %otherwise all data is from same group
        groupValues=unique(group);
        g=num2cell(groupValues); %creat cell array of group numbers
   
    
    end
    
    
    
    
    %perform test of uniformity for each group
    
    for g=1:length(groupValues)
        
        r_group=r(:,group==groupValues(g));
        z_group=z(group==groupValues(g),:);
        
        stats(g).r=r_group;
        
        % Plot mean and se of values
        m(:,g) = nanmean(r_group')';
        se(:,g) = ste(r_group')';
        
        
        %[h, p, ci, stat] = ttest(r');
        [h, p, ci, stat] = ttest(z_group);
        stats(g).descrip = 'T-test on Fisher''s r to Z transformed point-biserial correlations';
        stats(g).networknames = networknames;
        stats(g).p = p';
        stats(g).sig = h';
        stats(g).t = stat.tstat';
        stats(g).df = stat.df';
        
        %perform repeated measures anova  (two way anova with subject as the
        %row factor
        [~, stats(g).table_spatial, st]=anova2(z_group(~isnan(z_group(:,1)),:),1,'off');
        [c,~] = multcompare(st,'Display','off');
        stats(g).multcomp_spatial=[networknames(c(:,1))', networknames(c(:,2))', num2cell(c(:,3:6))];
        
        
        disp(['Table of correlations Group:' num2str(g)]);
        disp('--------------------------------------');
        disp(stats(g).descrip)
        
        print_matrix([m(:,g) stats(g).t stats(g).p stats(g).sig], {'R_avg' 'T' 'P' 'sig'}, networknames);
        disp(' ');
        
    end %groups
    
    
    if ~noplot
        
        groupColors=repmat(scn_standard_colors(size(m, 2)),3,1);
        groupColors={groupColors{:}};
        toplot=[];
        for i=1:length(groupValues)
            toplot=[toplot m(:,i)+se(:,i) m(:,i) m(:,i)-se(:,i)];
        end
        
        
        [hh, hhfill] = tor_polar_plot({toplot}, groupColors, {networknames}, 'nonneg');
        
        set(hh{1}(1:3:end), 'LineWidth', 1); %'LineStyle', ':', 'LineWidth', 2);
        set(hh{1}(3:3:end), 'LineWidth', 1); %'LineStyle', ':', 'LineWidth', 2);
        
        set(hh{1}(2:3:end), 'LineWidth', 4);
        set(hhfill{1}([3:3:end]), 'FaceAlpha', 1, 'FaceColor', 'w');
        set(hhfill{1}([2:3:end]), 'FaceAlpha', 0);
        set(hhfill{1}([1:3:end]), 'FaceAlpha', .3);
        
        handle_inds=1:3:length(hh{1});
        for g=1:length(groupValues)
            stats(g).line_handles = hh{1}(handle_inds(g):handle_inds(g)+2);
            stats(g).fill_handles = hhfill{1}(handle_inds(g):handle_inds(g)+2);
        end
        
        % doaverage
        
        hhtext = findobj(gcf, 'Type', 'text'); set(hhtext, 'FontSize', 20);
    end
end % doaverage
end % function



% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
%
% Sub-functions
%
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------


function [mask, networknames] = load_bucknerlab_maps

% Load Bucker Lab 1,000FC masks
% ------------------------------------------------------------------------

names = load('Bucknerlab_7clusters_SPMAnat_Other_combined_regionnames.mat');
img = which('rBucknerlab_7clusters_SPMAnat_Other_combined.img');

mask = fmri_data(img);  % loads image with integer coding of networks

networknames = names.rnames(1:7);
k = length(networknames);

newmaskdat = zeros(size(mask.dat, 1), k);

for i = 1:k  % breaks up into one map per image/network
    
    wh = mask.dat == i;
    
    nvox(1, i) = sum(wh);
    
    newmaskdat(:, i) = double(wh);
    
    
end

mask.dat = newmaskdat;

end  % function




function [mask, networknames] = load_npsplus

% Load NPS, PINES, Rejection, VPS,
% ------------------------------------------------------------------------

networknames = {'NPS' 'PINES' 'RomRejPattern' 'VPS'};

imagenames = {'weights_NSF_grouppred_cvpcr.img' ...  % NPS
    'Rating_Weights_LOSO_2.nii'  ...  % PINES
    'dpsp_rejection_vs_others_weights_final.nii' ... % rejection
    'bmrk4_VPS_unthresholded.nii'};

imagenames = check_image_names_get_full_path(imagenames);

mask = fmri_data(imagenames);  % loads images with spatial basis patterns

end  % function







function [mask, networknames] = load_kragelemotion

% Load NPS, PINES, Rejection, VPS,
% ------------------------------------------------------------------------

networknames = {'Amused' 'Angry' 'Content' 'Fearful' 'Neutral' 'Sad' 'Surprised'};

imagenames = { ...
    'mean_3comp_amused_group_emotion_PLS_beta_BSz_10000it.img' ...
    'mean_3comp_angry_group_emotion_PLS_beta_BSz_10000it.img' ...
    'mean_3comp_content_group_emotion_PLS_beta_BSz_10000it.img' ...
    'mean_3comp_fearful_group_emotion_PLS_beta_BSz_10000it.img' ...
    'mean_3comp_neutral_group_emotion_PLS_beta_BSz_10000it.img' ...
    'mean_3comp_sad_group_emotion_PLS_beta_BSz_10000it.img' ...
    'mean_3comp_surprised_group_emotion_PLS_beta_BSz_10000it.img'};

imagenames = check_image_names_get_full_path(imagenames);

mask = fmri_data(imagenames);  % loads images with spatial basis patterns

end % function




function imagenames = check_image_names_get_full_path(imagenames)

for i = 1:length(imagenames)
    
    if isempty(which(imagenames{i}))
        fprintf('CANNOT FIND %s \n', imagenames{i})
        error('Exiting.');
    end
    
    imagenames{i} = which(imagenames{i});
end
end





function [yfit, w, dist_from_hyplane] = crossVal_svm(svmobj,z,y,train_ind,test_ind)

dataobj = data('spider data', z(train_ind,:), y(train_ind,:));


% Training
[res, svmobj] = train(svmobj, dataobj);
res2 = test(svmobj, data('test data', z(test_ind,:), []));
yfit = res2.X;



if size(y,2)==1
    w = get_w(svmobj)';
    b0 = svmobj.b0;
    dist_from_hyplane = z(test_ind,:) * w + b0;
else
    for i = 1:size(res2.X,2)
        w(:,i) = get_w(svmobj{i})';
        b0(i) = svmobj{i}.b0;
        dist_from_hyplane(:,i) = z(test_ind,:) * w(:,i) + b0(i);
        
    end
end
end