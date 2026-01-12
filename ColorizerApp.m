classdef ColorizerApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        GridLayout    matlab.ui.container.GridLayout
        
        % Title Section
        TitleLabel    matlab.ui.control.Label
        SubtitleLabel matlab.ui.control.Label
        
        % Image Panels
        LeftPanel     matlab.ui.container.Panel
        ImageOriginal matlab.ui.control.Image
        RightPanel    matlab.ui.container.Panel
        ImageResult   matlab.ui.control.Image
        
        % Control Area
        ControlPanel  matlab.ui.container.Panel
        LoadButton    matlab.ui.control.Button
        ProcessButton matlab.ui.control.Button
        SaveButton    matlab.ui.control.Button 
        
        % Effects Controls
        EffectsPanel      matlab.ui.container.Panel
        SharpenCheckbox   matlab.ui.control.CheckBox
        ContrastCheckbox  matlab.ui.control.CheckBox
        ColormapDropDown  matlab.ui.control.DropDown
        ColormapLabel     matlab.ui.control.Label
    end

    properties (Access = private)
        InputPath string
        OutputPath string
        
        RawAIImage uint8      % Stores the raw output from Python
        FinalImage uint8      % Stores the image WITH effects (for saving)
    end

    methods (Access = private)

        % --- HELPER: APPLY EFFECTS & STORE RESULT ---
        function ApplyEffects(app)
            if isempty(app.RawAIImage)
                return;
            end
            
            % 1. Start with the clean AI output
            img = app.RawAIImage;
            
            % 2. Contrast Enhancement (CLAHE)
            if app.ContrastCheckbox.Value
                try
                    lab = rgb2lab(img);
                    L = lab(:,:,1) / 100;
                    L = adapthisteq(L, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
                    lab(:,:,1) = L * 100;
                    img = lab2rgb(lab, 'OutputType', 'uint8');
                catch
                    % Fallback if image isn't RGB
                    img = histeq(img);
                end
            end
            
            % 3. Edge Sharpening
            if app.SharpenCheckbox.Value
                img = imsharpen(img, 'Radius', 1, 'Amount', 1.5);
            end
            
            % 4. Colormap Overlays
            mapName = app.ColormapDropDown.Value;
            
            % FIX: Check against the CORRECT name 'Normal (Processed Color)'
            if ~strcmp(mapName, 'Normal (Processed Color)')
                
                % Ensure image is grayscale before applying map
                if size(img, 3) == 3
                    gray = im2gray(img);
                else
                    gray = img;
                end
                
                % Select Map
                switch mapName
                    case 'Thermal (Hot)'
                        cmap = hot(256);
                    case 'Scientific (Jet)'
                        cmap = jet(256);
                    case 'Cool (Cyan/Magenta)'
                        cmap = cool(256);
                    case 'Parula (Matlab)'
                        cmap = parula(256);
                    otherwise
                        % Fallback to avoid 'Unrecognized variable' error
                        cmap = jet(256); 
                end
                
                % Apply Colormap
                img = ind2rgb(gray2ind(gray, 256), cmap);
                img = uint8(img * 255);
            end
            
            % 5. SAVE THIS DATA to the 'FinalImage' property
            app.FinalImage = img;
            
            % 6. Display it
            app.ImageResult.ImageSource = img;
            
            % Enable Save Button now that we have a final image
            app.SaveButton.Enable = 'on';
        end

        % --- BUTTON: LOAD ---
        function LoadButtonPushed(app)
            [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp', 'Image Files'});
            if isequal(file, 0)
                return;
            end
            
            app.InputPath = fullfile(path, file);
            app.ImageOriginal.ImageSource = app.InputPath;
            app.ImageOriginal.Visible = 'on';
            
            % Reset States
            app.ProcessButton.Enable = 'on';
            app.SaveButton.Enable = 'off';
            app.ImageResult.ImageSource = '';
            app.RawAIImage = [];
            app.FinalImage = [];
        end

        % --- BUTTON: EXECUTE MODEL ---
        function ProcessButtonPushed(app)
            if isempty(app.InputPath)
                return;
            end
            
            app.UIFigure.Pointer = 'watch';
            drawnow;
            
            timestamp = char(datetime('now', 'Format', 'HHmmssSSS'));
            app.OutputPath = fullfile(pwd, ['result_', timestamp, '.png']);
            
            pythonExe = '/Users/ibrahim/Desktop/DIP/venv/bin/python';
            scriptName = 'backend.py';
            cmd = sprintf('"%s" "%s" "%s" "%s"', pythonExe, scriptName, app.InputPath, app.OutputPath);
            
            [status, cmdout] = system(cmd);
            
            app.UIFigure.Pointer = 'arrow';
            
            if status == 0
                % Load data into memory
                app.RawAIImage = imread(app.OutputPath);
                
                % Run the effects pipeline
                app.ApplyEffects();
            else
                uialert(app.UIFigure, ['Python Error: ' cmdout], 'Error', 'Icon', 'error');
            end
        end
        
        % --- BUTTON: SAVE FINAL RESULT ---
        function SaveButtonPushed(app)
            if isempty(app.FinalImage)
                return;
            end
            
            % Ask user where to save
            [file, path] = uiputfile({'*.png';'*.jpg';'*.bmp'}, 'Save Final Result As...');
            if isequal(file, 0)
                return;
            end
            
            savePath = fullfile(path, file);
            
            % Write the exact image data from memory to the disk
            imwrite(app.FinalImage, savePath);
            
            % FIX: Use 'Icon', 'success' to show a green checkmark instead of a red warning
            uialert(app.UIFigure, ['Saved to: ' savePath], 'Success', 'Icon', 'success');
        end

        % --- EFFECT CHANGED ---
        function EffectChanged(app)
            app.ApplyEffects();
        end
    end

    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.15 0.15 0.15];
            app.UIFigure.Position = [100 100 1100 700];
            app.UIFigure.Name = 'Deep Learning Colorizer Pro';

            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x'};
            app.GridLayout.RowHeight = {60, 40, '1x', 100};
            app.GridLayout.BackgroundColor = [0.15 0.15 0.15];

            % Header
            app.TitleLabel = uilabel(app.GridLayout);
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 24;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [1 1 1];
            app.TitleLabel.Text = 'Deep Learning Image Colorizer & Enhancer';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = [1 2];

            app.SubtitleLabel = uilabel(app.GridLayout);
            app.SubtitleLabel.HorizontalAlignment = 'center';
            app.SubtitleLabel.FontColor = [0.7 0.7 0.7];
            app.SubtitleLabel.Text = 'System Integration: MATLAB GUI + Python Deep Learning + Image Processing Filters';
            app.SubtitleLabel.Layout.Row = 2;
            app.SubtitleLabel.Layout.Column = [1 2];

            % Panels
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Title = 'Original Image';
            app.LeftPanel.BackgroundColor = [0.2 0.2 0.2];
            app.LeftPanel.TitlePosition = 'centertop';
            app.LeftPanel.FontSize = 14;
            app.LeftPanel.FontWeight = 'bold';
            app.LeftPanel.ForegroundColor = [1 0.3 0.3];
            app.LeftPanel.Layout.Row = 3;
            app.LeftPanel.Layout.Column = 1;

            app.ImageOriginal = uiimage(app.LeftPanel);
            app.ImageOriginal.Position = [20 20 500 400]; 
            
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Title = 'Enhanced Color Image';
            app.RightPanel.BackgroundColor = [0.2 0.2 0.2];
            app.RightPanel.TitlePosition = 'centertop';
            app.RightPanel.FontSize = 14;
            app.RightPanel.FontWeight = 'bold';
            app.RightPanel.ForegroundColor = [0.3 1 0.3];
            app.RightPanel.Layout.Row = 3;
            app.RightPanel.Layout.Column = 2;
            
            app.ImageResult = uiimage(app.RightPanel);
            app.ImageResult.Position = [20 20 500 400];

            % Controls
            app.ControlPanel = uipanel(app.GridLayout);
            app.ControlPanel.Layout.Row = 4;
            app.ControlPanel.Layout.Column = [1 2];
            app.ControlPanel.BackgroundColor = [0.15 0.15 0.15];
            app.ControlPanel.BorderType = 'none';
            
            % Button 1: Load
            app.LoadButton = uibutton(app.ControlPanel, 'push');
            app.LoadButton.BackgroundColor = [0.2 0.6 1];
            app.LoadButton.FontColor = [1 1 1];
            app.LoadButton.FontSize = 14;
            app.LoadButton.FontWeight = 'bold';
            app.LoadButton.Position = [30 30 130 40];
            app.LoadButton.Text = '1. Load';
            app.LoadButton.ButtonPushedFcn = @(btn,event) app.LoadButtonPushed();

            % Button 2: Execute Model
            app.ProcessButton = uibutton(app.ControlPanel, 'push');
            app.ProcessButton.BackgroundColor = [0.2 0.8 0.4];
            app.ProcessButton.FontColor = [1 1 1];
            app.ProcessButton.FontSize = 14;
            app.ProcessButton.FontWeight = 'bold';
            app.ProcessButton.Position = [180 30 130 40];
            app.ProcessButton.Text = '2. Execute Model';
            app.ProcessButton.Enable = 'off';
            app.ProcessButton.ButtonPushedFcn = @(btn,event) app.ProcessButtonPushed();
            
            % Button 3: Save (NEW!)
            app.SaveButton = uibutton(app.ControlPanel, 'push');
            app.SaveButton.BackgroundColor = [0.9 0.6 0.2]; % Orange
            app.SaveButton.FontColor = [1 1 1];
            app.SaveButton.FontSize = 14;
            app.SaveButton.FontWeight = 'bold';
            app.SaveButton.Position = [330 30 130 40];
            app.SaveButton.Text = '3. Save';
            app.SaveButton.Enable = 'off';
            app.SaveButton.ButtonPushedFcn = @(btn,event) app.SaveButtonPushed();

            % Effects Panel
            app.EffectsPanel = uipanel(app.ControlPanel);
            app.EffectsPanel.Title = 'Enhancements';
            app.EffectsPanel.Position = [500 5 550 85];
            app.EffectsPanel.BackgroundColor = [0.25 0.25 0.25];
            app.EffectsPanel.ForegroundColor = 'white';
            app.EffectsPanel.FontWeight = 'bold';
            
            app.SharpenCheckbox = uicheckbox(app.EffectsPanel);
            app.SharpenCheckbox.Text = 'Edge Sharpener';
            app.SharpenCheckbox.FontColor = 'white';
            app.SharpenCheckbox.Position = [20 30 105 22];
            app.SharpenCheckbox.ValueChangedFcn = @(btn, event) app.EffectChanged();
            
            app.ContrastCheckbox = uicheckbox(app.EffectsPanel);
            app.ContrastCheckbox.Text = 'Contrast Enhancer';
            app.ContrastCheckbox.FontColor = 'white';
            app.ContrastCheckbox.Position = [140 30 130 22];
            app.ContrastCheckbox.ValueChangedFcn = @(btn, event) app.EffectChanged();
            
            app.ColormapLabel = uilabel(app.EffectsPanel);
            app.ColormapLabel.Text = 'Color Effect:';
            app.ColormapLabel.FontColor = 'white';
            app.ColormapLabel.Position = [280 30 70 22];
            
            app.ColormapDropDown = uidropdown(app.EffectsPanel);
            app.ColormapDropDown.Items = {'Normal (Processed Color)', 'Thermal (Hot)', 'Scientific (Jet)', 'Cool (Cyan/Magenta)', 'Parula (Matlab)'};
            app.ColormapDropDown.Position = [350 30 180 22];
            app.ColormapDropDown.ValueChangedFcn = @(btn, event) app.EffectChanged();

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = ColorizerApp
            createComponents(app)
        end
        function delete(app)
            delete(app.UIFigure)
        end
    end
end