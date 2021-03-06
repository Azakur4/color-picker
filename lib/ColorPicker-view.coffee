# ----------------------------------------------------------------------------
#  Color Picker: view
# ----------------------------------------------------------------------------

    module.exports = ->
        SmartColor: (require './modules/SmartColor')()
        Emitter: (require './modules/Emitter')()
        Inspector: (require './modules/Inspector')()

        extensions: {}
        getExtension: (extensionName) -> @extensions[extensionName]

        isFirstOpen: yes
        canOpen: yes
        element: null
        selection: null

        listeners: []

    # -------------------------------------
    #  Create and activate Color Picker view
    # -------------------------------------
        activate: ->
            _workspace = atom.workspace
            _workspaceView = atom.views.getView _workspace

        #  Create element
        # ---------------------------
            @element =
                el: do ->
                    _el = document.createElement 'div'
                    _el.classList.add 'ColorPicker'

                    return _el
                # Utility functions
                remove: -> @el.parentNode.removeChild @el

                addClass: (className) -> @el.classList.add className; return this
                removeClass: (className) -> @el.classList.remove className; return this
                hasClass: (className) -> @el.classList.contains className

                width: -> @el.offsetWidth
                height: -> @el.offsetHeight

                setHeight: (height) -> @el.style.height = "#{ height }px"

                hasChild: (child) ->
                    if child and _parent = child.parentNode
                        if child is @el
                            return true
                        else return @hasChild _parent
                    return false

                # Open & Close the Color Picker
                isOpen: -> @hasClass 'is--open'
                open: -> @addClass 'is--open'
                close: -> @removeClass 'is--open'

                # Flip & Unflip the Color Picker
                isFlipped: -> @hasClass 'is--flipped'
                flip: -> @addClass 'is--flipped'
                unflip: -> @removeClass 'is--flipped'

                # Set Color Picker position
                # - x {Number}
                # - y {Number}
                setPosition: (x, y) ->
                    @el.style.left = "#{ x }px"
                    @el.style.top = "#{ y }px"
                    return this

                # Add a child on the ColorPicker element
                add: (element) ->
                    @el.appendChild element
                    return this
            @loadExtensions()

        #  Close the Color Picker on any activity unrelated to it
        #  but also emit events on the Color Picker
        # ---------------------------
            @listeners.push ['mousedown', onMouseDown = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseDown e, _isPickerEvent
                return @close() unless @element.hasChild e.target]
            window.addEventListener 'mousedown', onMouseDown

            @listeners.push ['mousemove', onMouseMove = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseMove e, _isPickerEvent]
            window.addEventListener 'mousemove', onMouseMove

            @listeners.push ['mouseup', onMouseUp = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseUp e, _isPickerEvent]
            window.addEventListener 'mouseup', onMouseUp

            @listeners.push ['mousewheel', onMouseWheel = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseWheel e, _isPickerEvent]
            window.addEventListener 'mousewheel', onMouseWheel

            _workspaceView.addEventListener 'keydown', (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitKeyDown e, _isPickerEvent
                return @close()

            # Close it on scroll also
            atom.workspace.observeTextEditors (editor) =>
                _subscriptionTop = editor.onDidChangeScrollTop => @close()
                _subscriptionLeft = editor.onDidChangeScrollLeft => @close()

                editor.onDidDestroy ->
                    _subscriptionTop.dispose()
                    _subscriptionLeft.dispose()
                @onBeforeDestroy ->
                    _subscriptionTop.dispose()
                    _subscriptionLeft.dispose()
                return

            # Close it when the window resizes
            @listeners.push ['resize', onResize = =>
                @close()]
            window.addEventListener 'resize', onResize

            # Close it when the active item is changed
            _workspace.getActivePane().onDidChangeActiveItem => @close()

        #  Place the Color Picker element
        # ---------------------------
            @close()

            # TODO: Is this really the best way to do this? Hint: Probably not
            atom.views.getView atom.workspace
                .querySelector '.vertical'
                .appendChild @element.el
            return this

    # -------------------------------------
    #  Destroy the view and unbind events
    # -------------------------------------
        destroy: ->
            @emitBeforeDestroy()

            for [_event, _listener] in @listeners
                window.removeEventListener _event, _listener
            @element.remove()

    # -------------------------------------
    #  Load Color Picker extensions // more like dependencies
    # -------------------------------------
        loadExtensions: ->
            # TODO: This is really stupid. Should this be done with `fs` or something?
            # TODO: Extension files have pretty much the same base. Simplify?
            for _extension in ['Arrow', 'Color', 'Body', 'Saturation', 'Alpha', 'Hue', 'Definition', 'Return', 'Format']
                _requiredExtension = (require "./extensions/#{ _extension }")(this)
                @extensions[_extension] = _requiredExtension
                _requiredExtension.activate?()
            return

    # -------------------------------------
    #  Set up events and handling
    # -------------------------------------
        # Mouse events
        emitMouseDown: (e, isOnPicker) ->
            @Emitter.emit 'mouseDown', e, isOnPicker
        onMouseDown: (callback) ->
            @Emitter.on 'mouseDown', callback

        emitMouseMove: (e, isOnPicker) ->
            @Emitter.emit 'mouseMove', e, isOnPicker
        onMouseMove: (callback) ->
            @Emitter.on 'mouseMove', callback

        emitMouseUp: (e, isOnPicker) ->
            @Emitter.emit 'mouseUp', e, isOnPicker
        onMouseUp: (callback) ->
            @Emitter.on 'mouseUp', callback

        emitMouseWheel: (e, isOnPicker) ->
            @Emitter.emit 'mouseWheel', e, isOnPicker
        onMouseWheel: (callback) ->
            @Emitter.on 'mouseWheel', callback

        # Key events
        emitKeyDown: (e, isOnPicker) ->
            @Emitter.emit 'keyDown', e, isOnPicker
        onKeyDown: (callback) ->
            @Emitter.on 'keyDown', callback

        # Position Change
        emitPositionChange: (position, colorPickerPosition) ->
            @Emitter.emit 'positionChange', position, colorPickerPosition
        onPositionChange: (callback) ->
            @Emitter.on 'positionChange', callback

        # Opening
        emitOpen: ->
            @Emitter.emit 'open'
        onOpen: (callback) ->
            @Emitter.on 'open', callback

        # Before opening
        emitBeforeOpen: ->
            @Emitter.emit 'beforeOpen'
        onBeforeOpen: (callback) ->
            @Emitter.on 'beforeOpen', callback

        # Closing
        emitClose: ->
            @Emitter.emit 'close'
        onClose: (callback) ->
            @Emitter.on 'close', callback

        # Before destroying
        emitBeforeDestroy: ->
            @Emitter.emit 'beforeDestroy'
        onBeforeDestroy: (callback) ->
            @Emitter.on 'beforeDestroy', callback

        # Input Color
        emitInputColor: (smartColor, wasFound=true) ->
            @Emitter.emit 'inputColor', smartColor, wasFound
        onInputColor: (callback) ->
            @Emitter.on 'inputColor', callback

        # Input Variable
        emitInputVariable: (match) ->
            @Emitter.emit 'inputVariable', match
        onInputVariable: (callback) ->
            @Emitter.on 'inputVariable', callback

        # Input Variable Color
        emitInputVariableColor: (smartColor, pointer) ->
            @Emitter.emit 'inputVariableColor', smartColor, pointer
        onInputVariableColor: (callback) ->
            @Emitter.on 'inputVariableColor', callback

    # -------------------------------------
    #  Colors in string
    # -------------------------------------
        getColorsInString: (string) ->
            View = this

            _colors = []; for {type, regex} in (require './modules/ColorRegexes')
                continue unless _matches = string.match regex

                for _match in _matches then do (type, _match) =>
                    return if (_index = string.indexOf _match) is -1

                    _matchColor =
                        match: _match
                        type: type
                        start: _index
                        end: _index + _match.length

                        # Set up a function to obtain a SmartColor from the match
                        # TODO this is ugly. Is there a better way to do this?
                        # Since ColorRegexes and SmartColor are separate modules,
                        # I kinda can't uppercase type and _assume_ they will
                        # be the same in the SmartColor function...
                        getSmartColor: -> return switch type
                            when 'rgb' then View.SmartColor.RGB _match
                            when 'rgba' then View.SmartColor.RGBA _match
                            when 'hsl' then View.SmartColor.HSL _match
                            when 'hsla' then View.SmartColor.HSLA _match
                            when 'hex' then View.SmartColor.HEX _match
                            when 'hexa' then View.SmartColor.HEXA _match
                            when 'vec3' then View.SmartColor.VEC _match
                            when 'vec4' then View.SmartColor.VECA _match
                            when 'hsv' then View.SmartColor.HSV _match
                            when 'hsva' then View.SmartColor.HSVA _match
                    _colors.push _matchColor

                    # Remove the match from the line content string to
                    # “mark it” as having been “spent”. Be careful to keep the
                    # correct amount of characters in the string as this is
                    # later used to see which match fits best, if any
                    string = string.replace _match, (new Array (_match.length + 1)).join ' '
                    return
            return _colors

    # -------------------------------------
    #  Open the Color Picker
    # -------------------------------------
        open: ->
            return unless @canOpen
            @emitBeforeOpen()

            Editor = atom.workspace.getActiveTextEditor()
            EditorView = atom.views.getView Editor
            EditorShadowRoot = EditorView.shadowRoot

            # Reset selection
            @selection = null

        #  Find the current cursor
        # ---------------------------
            Cursor = Editor.getLastCursor()

            # Fail if the cursor isn't visible
            _visibleRowRange = Editor.getVisibleRowRange()
            _cursorRow = Cursor.getBufferRow()

            return if (_cursorRow < _visibleRowRange[0] - 1) or (_cursorRow > _visibleRowRange[1])

            # Try matching the contents of the current line to color regexes
            _lineContent = Cursor.getCurrentBufferLine()
            _colorMatches = @getColorsInString _lineContent

            # Figure out which of the matches is the one the user wants
            _cursorColumn = Cursor.getBufferColumn()
            _match = do -> for _match in _colorMatches
                return _match if _match.start <= _cursorColumn and _match.end >= _cursorColumn

            # If we've got a match, we should select it
            if _match
                Editor.clearSelections()

                _selection = Editor.addSelectionForBufferRange [
                    [_cursorRow, _match.start]
                    [_cursorRow, _match.end]]
                @selection = match: _match, row: _cursorRow
            # But if we don't have a match, center the Color Picker on last cursor
            else
                _cursorPosition = Cursor.getPixelRect()
                @selection = column: Cursor.getBufferColumn(), row: _cursorRow

        #  Emit
        # ---------------------------
            if _match
                # TODO: Fragile. Should be _match.isVariable() or something cool
                if _match.type in ['variable:sass', 'variable:less']
                    @emitInputVariable _match

                    # TODO: Add loading animation
                    # TODO: Don't find variables in files with non-fitting
                    # extensions. For example, a Sass variable should only be
                    # found if the extension is .sass or .scss

                    # Find the variable definition
                    getDefinition = (variable, type, pointer) =>
                        return (@Inspector variable, type).then (definition) =>
                            throw (new Error 'No definition') unless definition

                            _colorMatch = (@getColorsInString definition.definition)[0]
                            throw (new Error 'Definition not a color') unless _colorMatch

                            # Save the original pointer
                            pointer ?= definition.pointer

                            # Look deeper and continue digging if the
                            # definition is a variable
                            if _colorMatch.type in ['variable:sass', 'variable:less']
                                return getDefinition _colorMatch.match, _colorMatch.type, pointer
                            _colorMatch.pointer = pointer

                            # Return the definition if we found it
                            return _colorMatch
                    getDefinition _match.match, _match.type
                        .then (color) =>
                            @emitInputVariableColor color.getSmartColor(), color.pointer
                        .catch (error) =>
                            @emitInputVariableColor false
                else @emitInputColor _match.getSmartColor()
            # No match, but `randomColor` option is set
            else if atom.config.get 'color-picker.randomColor'
                _randomColor = @SmartColor.RGB 'rgb(' + ([
                    ((Math.random() * 255) + .5) << 0
                    ((Math.random() * 255) + .5) << 0
                    ((Math.random() * 255) + .5) << 0].join ', ') + ')'

                # Convert to `preferredColor`, and then emit it
                _preferredFormat = atom.config.get 'color-picker.preferredFormat'

                if _randomColor.type isnt _preferredFormat
                    _convertedColor = _randomColor["to#{ _preferredFormat }"]()
                    _randomColor = @SmartColor[_preferredFormat] _convertedColor

                @emitInputColor _randomColor, false
            # No match, and it's the first open
            else if @isFirstOpen
                _redColor = @SmartColor.RGB 'rgb(255, 0, 0)'

                # Convert to `preferredColor`, and then emit it
                _preferredFormat = atom.config.get 'color-picker.preferredFormat'

                if _redColor.type isnt _preferredFormat
                    _convertedColor = _redColor["to#{ _preferredFormat }"]()
                    _redColor = @SmartColor[_preferredFormat] _convertedColor
                @isFirstOpen = no

                @emitInputColor _redColor, false

        #  After (& if) having selected text (as this might change the scroll
        #  position) gather information about the Editor
        # ---------------------------
            _editorWidth = Editor.getWidth()
            _editorHeight = Editor.getHeight()
            _editorOffsetTop = EditorView.parentNode.offsetTop
            _editorOffsetLeft = EditorShadowRoot.querySelector('.scroll-view').offsetLeft
            _editorScrollTop = Editor.getScrollTop()

            _lineHeight = Editor.getLineHeightInPixels()
            _lineOffsetLeft = EditorShadowRoot.querySelector('.line').offsetLeft

            # Tinker with the `Cursor.getPixelRect` object to center it on
            # the middle of the selection range
            # TODO: There can be lines over more than one row
            if _match
                _selectionPosition = _selection.marker.getPixelRange()
                _cursorPosition = Cursor.getPixelRect()
                _cursorPosition.left = _selectionPosition.end.left - ((_selectionPosition.end.left - _selectionPosition.start.left) / 2)

        #  Figure out where to place the Color Picker
        # ---------------------------
            _totalOffsetLeft = _editorOffsetLeft + _lineOffsetLeft

            _position =
                x: _cursorPosition.left + _totalOffsetLeft
                y: _cursorPosition.top + _cursorPosition.height - _editorScrollTop + _editorOffsetTop

        #  Figure out where to actually place the Color Picker by
        #  setting up boundaries and flipping it if necessary
        # ---------------------------
            _colorPickerPosition =
                x: do =>
                    _halfColorPickerWidth = (@element.width() / 2) << 0

                    # Make sure the Color Picker isn't too far to the left
                    _x = Math.max (_totalOffsetLeft / 2), (_position.x - _halfColorPickerWidth)
                    # Make sure the Color Picker isn't too far to the right
                    _x = Math.min (_editorWidth - _totalOffsetLeft - _halfColorPickerWidth), _x

                    # TODO: It is overflowing on the right

                    return _x
                y: do =>
                    @element.unflip()

                    # TODO: It's not really working out great

                    # If the color picker is too far down, flip it
                    if @element.height() + _position.y > _editorHeight + _editorOffsetTop
                        @element.flip()
                        return _position.y - _lineHeight - @element.height()
                    # But if it's fine, keep the Y position
                    else return _position.y

            # Set Color Picker position and emit events
            @element.setPosition _colorPickerPosition.x, _colorPickerPosition.y
            @emitPositionChange _position, _colorPickerPosition

            # Open the Color Picker
            requestAnimationFrame => # wait for class delay
                @element.open()
                @emitOpen()
            return

    # -------------------------------------
    #  Replace selected color
    # -------------------------------------
        canReplace: yes
        replace: (color) ->
            return unless @canReplace
            @canReplace = no

            Editor = atom.workspace.getActiveTextEditor()
            Editor.clearSelections()

            if @selection.match
                _cursorStart = @selection.match.start
                _cursorEnd = @selection.match.end
            else _cursorStart = _cursorEnd = @selection.column

            # Select the color we're going to replace
            Editor.addSelectionForBufferRange [
                [@selection.row, _cursorStart]
                [@selection.row, _cursorEnd]]
            Editor.replaceSelectedText null, => color

            # Select the newly inserted color and move the cursor to it
            setTimeout =>
                Editor.setCursorBufferPosition [
                    @selection.row, _cursorStart]
                Editor.clearSelections()

                # Update selection length
                @selection.match?.end = _cursorStart + color.length

                Editor.addSelectionForBufferRange [
                    [@selection.row, _cursorStart]
                    [@selection.row, _cursorStart + color.length]]
                return setTimeout ( => @canReplace = yes), 100
            return

    # -------------------------------------
    #  Close the Color Picker
    # -------------------------------------
        close: ->
            @element.close()
            @emitClose()
