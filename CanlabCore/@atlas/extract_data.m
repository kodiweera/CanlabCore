function [parcel_means, parcel_pattern_expression, parcel_valence] = extract_data(obj, data_obj, varargin)
% Atlas object-class method that extracts and averages data stored in an
% fmri_data object [data_obj] basd on atlas regions.
%
% - Runs image_vector.apply_parcellation
%
% - Mask/Atlas image does not have to be in the same space as the images to extract from.
%   Resamples the data_obj to be in the same space as the atlas obj if needed.
%
% - If optional weight_map obj is entered, will apply local pattern weights.
%
% :Usage:
% ::
%
%    data_table = extract_data(extract_data, data_obj, [weight_map_obj])
%
% :Inputs:
%
%   - obj:      atlas object 
%   - data_obj: fmri_data object
%
% :Optional inputs:
%
%   **see help for image_vector.apply_parcellation.
%
%   **pattern_expression:**
%       followed by an fmri_data object with multivariate pattern to apply.
%       local patterns in each parcel are applied, and pattern responses
%       returned for each parcel.
%
%   **correlation:**
%        calculate the pearson correlation coefficient of each
%        image in dat and the values in the mask.
%
%   **norm_mask:**
%        normalize the mask weights by L2 norm
%
%   **ignore_missing:**
%        used with pattern expression only. Ignore weights on voxels
%        with zero values in test image. If this is not entered, the function will
%        check for these values and give a warning.
%
%   **cosine_similarity:**
%        used with pattern expression only. scales expression by product of
%        l2 norms (norm(mask)*norm(dat))
%
%
% :Examples:
% ::
%
%   [nps, npsnames] = load_image_set('npsplus');
%   siips = get_wh_image(nps, 4);
%   nps = get_wh_image(nps, 1);
%
%    load pain_pathways_atlas_obj.mat
%    test_data_obj = load_image_set('pain');
%    [parcel_means, parcel_pattern_expression, parcel_valence] = extract_data(pain_pathways_finegrained, test_data_obj, 'pattern_expression', nps, 'cosine_similarity');
%
%
% :See also:
%
% For an non-object-oriented alternative, see extract_image_data.m
% fmri_data.extract_roi_averages, apply_parcellation.m

% Programmers' notes:
% This function is different from fmri_data.extract_roi_averages
% Better to have only one function of record in the future...
% Note: 
% cl = extract_roi_averages(imgs, atlas_obj{1});
% accomplishes the same task as apply_parcellation, returns slightly different values due to interpolation.  

[parcel_means, parcel_pattern_expression, parcel_valence] = deal([]);

[parcel_means, parcel_pattern_expression, parcel_valence] = apply_parcellation(data_obj, obj, varargin{:});

end % function


