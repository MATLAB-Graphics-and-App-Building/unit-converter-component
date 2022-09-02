classdef unitConverterComponent < matlab.ui.componentcontainer.ComponentContainer
    % unitConverterComponent converts input into a standardized unit
    %
    % c = unitConverterComponent(parent) creates a unit converter in the
    % specified parent container. The parent can be a figure or one of its
    % child containers.
    %
    % c = unitConverterComponent(____, 'TargetUnit', Unit) specifies the
    % target unit that the input values are converted to, containing a
    % dropdown and numeric edit field. Use this option with any of the
    % input argument combinations in the previous syntaxes.
    %
    % c = unitConverterComponent(____, Name, Value) creates a unit
    % converter with properties specified by one or more name-value
    % arguments.

    % Copyright 2022 The MathWorks, Inc.

    properties
        DisplayValue (1,1) {mustBeNumeric} = 0
        FontSize (1,:) {mustBePositive} = 14
        FontName (1,:) {mustBeValidFont} = 'Arial'
        FontColor {validatecolor} = [0 0 0]
        TextFieldLayout (1,:) {mustBeMember(TextFieldLayout, {'side-by-side', 'stacked'})} = 'side-by-side'
    end

    properties (Dependent)
        Value
        ConversionTable (:,1) {mustBeValidConversionTable}
        DisplayUnit (1,1) string {mustBeTextScalar}
        TargetUnit (1,1) string {mustBeTextScalar}
    end

    properties (Access = protected)
        % Use an internal conversion table to store the conversion table,
        % display unit, and target unit. It allows the user to freely
        % change the dependent properties while storing the most recent
        % state of the component.
        InternalConversionTable (:,3) = makeDefaultInternalConversionTable()
    end

    events (HasCallbackProperty, NotifyAccess = private)
        ValueChanged
    end

    properties (Access = private, Transient, NonCopyable)
        Grid matlab.ui.container.GridLayout 
        EditField matlab.ui.control.NumericEditField
        DropDown matlab.ui.control.DropDown
    end

    methods(Access = private)
        function valChanged(obj)
            notify(obj, "ValueChanged");
        end
    end

    methods(Static)
        function tbl = makeDefaultConversionTable()
            tbl = makeDefaultConversionTable();
        end
    end

    methods
        function tbl = get.ConversionTable(obj)
            % Conversion table is contained within the row names and first
            % column of the internal table
            tbl = obj.InternalConversionTable(:,1);
        end

        function set.ConversionTable(obj, tbl)
            % Input validation
            mustBeValidConversionTable(tbl);
            currentDisplayUnit = obj.DisplayUnit;
            currentTargetUnit = obj.TargetUnit;

            % When DisplayUnit isn't present, set it to the first unit
            if sum(strcmp(tbl.Properties.RowNames, currentDisplayUnit)) ~= 1
                currentDisplayUnit = tbl.Properties.RowNames(1);
            end

            % Validate target unit is in the table - if not, set it to the
            % unit with a conversion factor of 1
            if sum(strcmp(tbl.Properties.RowNames, currentTargetUnit)) ~= 1
                currentTargetUnit = tbl.Properties.RowNames(tbl{:,1} == 1);
            end

            % Update conversion table while also storing the display and
            % target unit
            tbl.DisplayUnit = strcmp(tbl.Properties.RowNames, currentDisplayUnit);
            tbl.TargetUnit = strcmp(tbl.Properties.RowNames, currentTargetUnit);
            obj.InternalConversionTable = tbl;

            % Update dropdown with the new units and the display unit
            obj.DropDown.Items = tbl.Properties.RowNames;
            obj.DropDown.Value = currentDisplayUnit;
        end

        function set.FontColor(obj, color)
            obj.FontColor = validatecolor(color);
        end

        function set.FontName(obj, font)
            obj.FontName = mustBeValidFont(font);
        end

        function tbl = get.InternalConversionTable(obj)
            tbl = obj.InternalConversionTable;

            % Update internal table with the display unit
            tbl.DisplayUnit = ...
                strcmp(tbl.Properties.RowNames, obj.DisplayUnit);
        end

        function set.DisplayUnit(obj, val)
            mustBeValidUnit(val, obj.ConversionTable);
            obj.DropDown.Value = val;
        end

        function val = get.DisplayUnit(obj)
            val = obj.DropDown.Value;
        end

        function set.TargetUnit(obj, val)
            % Allow uppercase target units to be accepted
            val = lower(val);
            mustBeValidUnit(val, obj.ConversionTable);

            % Update internal table with the new target unit
            obj.InternalConversionTable.TargetUnit = ...
                strcmp(obj.InternalConversionTable.Properties.RowNames, val);
        end

        function val = get.TargetUnit(obj)
            val = obj.InternalConversionTable.Properties.RowNames(...
                obj.InternalConversionTable.TargetUnit);
        end

        function set.DisplayValue(obj, val)
            obj.EditField.Value = val; %#ok<MCSUP> 
        end

        function val = get.DisplayValue(obj)
            val = obj.EditField.Value;
        end

        function set.Value(obj, val)
            % Convert from the target unit to the display unit
            obj.DisplayValue = convertUnit(obj.ConversionTable, val, obj.TargetUnit, obj.DisplayUnit);
        end

        function val = get.Value(obj)
            % Convert to the standard unit (default is meters), then to the target unit
            val = convertUnit(obj.ConversionTable, obj.DisplayValue, obj.DisplayUnit, obj.TargetUnit);
        end
    end

    methods(Access = protected)
        function setup(obj)
            % Create UI components
            obj.Grid = uigridlayout(obj, 'Padding', 0);
            obj.EditField = uieditfield(obj.Grid,'numeric', ...
                'HorizontalAlignment', 'center');   
            obj.EditField.ValueChangedFcn = @(~, ~) obj.valChanged;
            
            tbl = makeDefaultConversionTable();
            obj.DropDown = uidropdown(obj.Grid, ...
                'Editable', 'on', ...
                'Items', tbl.Properties.RowNames);
            obj.DropDown.ValueChangedFcn = @(~, ~) obj.valChanged;
        end
 
        function update(obj)
            % Update the stylistic properties for the UI components
            obj.Grid.BackgroundColor = obj.BackgroundColor;
            obj.DropDown.FontName = obj.FontName;
            obj.EditField.FontName = obj.FontName;
            obj.DropDown.FontColor = obj.FontColor;
            obj.EditField.FontColor = obj.FontColor;
            obj.DropDown.FontSize = obj.FontSize;
            obj.EditField.FontSize = obj.FontSize;

            % Update layout of UI components
            if strcmp(obj.TextFieldLayout, 'side-by-side')
                obj.Position(3:4) = [150 25];
                obj.Grid.RowHeight = {'fit'};
                obj.Grid.ColumnWidth = {'1x','fit'};
                obj.DropDown.Layout.Row = 1;
                obj.DropDown.Layout.Column = 2;
            elseif strcmp(obj.TextFieldLayout, 'stacked') 
                obj.Position(3:4) = [100 60];
                obj.Grid.RowHeight = {'fit','fit'};
                obj.Grid.ColumnWidth = {'1x'};
                obj.DropDown.Layout.Row = 2;
                obj.DropDown.Layout.Column = 1;
            end
        end
    end
end

function unitTable = makeDefaultConversionTable()
    unit = [
        "mile";
        "foot";
        "inch";
        "meter";
        "yard"
    ];

    % Taken from wikipedia:
    % https://en.wikipedia.org/wiki/Conversion_of_units#Length
    ConversionFactors = [
        1609.344;
        0.3048;
        0.0254;
        1;
        0.9144;
    ];

    unitTable = table(ConversionFactors, 'RowNames', unit);
end

function tbl = makeDefaultInternalConversionTable()
    t = makeDefaultConversionTable();
    t.DisplayUnit = strcmp(t.Properties.RowNames, 'mile');
    t.TargetUnit = t.ConversionFactors == 1;
    tbl = t;
end


function mustBeValidConversionTable(tbl)
    if isempty(tbl.Properties.RowNames)
        error("Conversion table must have row names.");
    elseif width(tbl) ~= 1
        error("Conversion table must have one column containing the conversion factors.")
    elseif ~isnumeric(tbl{:,1})
        error("Conversion factors must all be numeric.");
    elseif ~any(tbl{:,1} == 1)
        error("Standard unit must be in conversion table with a conversion factor of 1.")
    end
end

function font = mustBeValidFont(font)
    font = validatestring(font, listfonts);
end

function mustBeValidUnit(unit, tbl)
    mustBeMember(unit, tbl.Properties.RowNames);
end

function val = convertUnit(tbl, fromValue, fromUnit, toUnit)
    factor = tbl{fromUnit, :};
    defaultVal = fromValue * factor;
    val = defaultVal / (tbl{toUnit, :});
end
