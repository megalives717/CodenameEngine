package funkin.editors.character;

import funkin.editors.character.CharacterAnimsWindow.CharacterAnimButtons;
import funkin.backend.utils.XMLUtil.AnimData;
import flixel.math.FlxPoint;
import flixel.animation.FlxAnimation;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import flixel.input.keyboard.FlxKey;
import funkin.game.Character;

class CharacterEditor extends UIState {
	var __character:String;
	public var character:Character;

	public static var instance(get, null):CharacterEditor;

	private static inline function get_instance()
		return FlxG.state is CharacterEditor ? cast FlxG.state : null;

	/**
	 * CHARACTER UI STUFF
	*/
	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	// WINDOWS
	public var characterPropertiresWindow:CharacterPropertiesWindow;
	public var characterAnimsWindow:CharacterAnimsWindow;
	
	// camera for the character itself so that it can be unzoomed/zoomed in again
	public var charCamera:FlxCamera;
	// camera for the animations list
	public var animsCamera:FlxCamera;
	// camera for the ui
	public var uiCamera:FlxCamera;

	public var undoList:Array<CharacterChange> = [];
	public var redoList:Array<CharacterChange> = [];

	public function new(character:String) {
		super();
		__character = character;
	}

	public override function create() {
		super.create();
		
		topMenu = [
			{
				label: "File",
				childs: [
					{
						label: "New",
						onSelect: _file_new,
					},
					null,
					{
						label: "Save",
						keybind: [CONTROL, S],
						onSelect: _file_save,
					},
					{
						label: "Save As...",
						keybind: [CONTROL, SHIFT, S],
						onSelect: _file_saveas,
					},
					null,
					{
						label: "Exit",
						onSelect: _file_exit
					}
				]
			},
			{
				label: "Edit",
				childs: [
					{
						label: "Undo",
						keybind: [CONTROL, Z],
						onSelect: _edit_undo
					},
					{
						label: "Redo",
						keybinds: [[CONTROL, Y], [CONTROL, SHIFT, Z]],
						onSelect: _edit_redo
					}
				]
			},
			{
				label: "Character",
				childs: [
					{
						label: "New Animation",
						keybind: [CONTROL, N],
						onSelect: _char_add_anim,
					},
					{
						label: "Edit Animation",
						onSelect: _char_edit_anim,
					},
					{
						label: "Delete Animation",
						keybind: [DELETE],
						onSelect: _char_remove_anim,
					},
					null,
					{
						label: "Edit Info",
						onSelect: _char_edit_info,
					}
				]
			},
			{
				label: "Playback",
				childs: [
					{
						label: "Play Animation",
						keybind: [SPACE],
						onSelect: _playback_play_anim,
					},
					{
						label: "Stop Animation",
						onSelect: _playback_stop_anim
					}
				]
			},
			{
				label: "Offsets",
				childs: [
					{
						label: "Move Left",
						keybind: [LEFT],
						onSelect: _offsets_left,
					},
					{
						label: "Move Up",
						keybind: [UP],
						onSelect: _offsets_up,
					},
					{
						label: "Move Down",
						keybind: [DOWN],
						onSelect: _offsets_down,
					},
					{
						label: "Move Right",
						keybind: [RIGHT],
						onSelect: _offsets_right,
					},
					null,
					{
						label: "Move Extra Left",
						keybind: [SHIFT, LEFT],
						onSelect: _offsets_extra_left,
					},
					{
						label: "Move Extra Up",
						keybind: [SHIFT, UP],
						onSelect: _offsets_extra_up,
					},
					{
						label: "Move Extra Down",
						keybind: [SHIFT, DOWN],
						onSelect: _offsets_extra_down,
					},
					{
						label: "Move Extra Right",
						keybind: [SHIFT, RIGHT],
						onSelect: _offsets_extra_right,
					},
					null,
					{
						label: "Clear Offsets",
						keybind: [CONTROL, R],
						onSelect: _offsets_clear,
					}
				]
			},
			{
				label: "View",
				childs: [
					{
						label: "Zoom in",
						keybind: [CONTROL, NUMPADPLUS],
						onSelect: _view_zoomin
					},
					{
						label: "Zoom out",
						keybind: [CONTROL, NUMPADMINUS],
						onSelect: _view_zoomout
					},
					{
						label: "Reset zoom",
						keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_zoomreset
					},

				]
			},
		];

		charCamera = FlxG.camera;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;
		animsCamera = new FlxCamera(800-23,140+23+30+46,450+23,511-24-30);
		animsCamera.bgColor = 0;

		FlxG.cameras.add(uiCamera);
		FlxG.cameras.add(animsCamera);

		character = new Character(0,0,__character);
		character.debugMode = true;
		character.cameras = [charCamera];
		add(character);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		characterPropertiresWindow = new CharacterPropertiesWindow();
		characterAnimsWindow = new CharacterAnimsWindow(character);
		uiGroup.add(characterPropertiresWindow);
		uiGroup.add(characterAnimsWindow);

		playAnimation(character.getNameList()[0]);

		add(topMenuSpr);
		add(uiGroup);
	}

	private var movingCam:Bool = false;
	private var camDrag:FlxPoint = FlxPoint.get(0,0);

	private var nextScroll:FlxPoint = FlxPoint.get(0,0);

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (true) {
			if(FlxG.keys.justPressed.ANY)
				UIUtil.processShortcuts(topMenu);
		}

		if (character != null)
			characterPropertiresWindow.characterInfo.text = '(Num) Animations: ${character.getNameList().length}\nFlipped: ${character.flipX}\nSprite: ${character.sprite}\nAnim: ${character.getAnimName()}';

		if (FlxG.mouse.wheel != 0 && !(characterPropertiresWindow.hovered || characterAnimsWindow.hovered)) {
			zoom += 0.25 * FlxG.mouse.wheel;
			__camZoom = Math.pow(2, zoom);
		}

		if (FlxG.mouse.justPressedMiddle) {
			FlxG.mouse.getScreenPosition(charCamera, camDrag);
			camDrag += charCamera.scroll;
		}

		if (FlxG.mouse.pressedMiddle) {
			var pos = FlxG.mouse.getScreenPosition(charCamera);
			nextScroll.set((camDrag.x - pos.x), (camDrag.y - pos.y));
		}

		charCamera.scroll.set(
			lerp(charCamera.scroll.x, nextScroll.x, 0.25),
			lerp(charCamera.scroll.y, nextScroll.y, 0.25)
		);

		charCamera.zoom = lerp(charCamera.zoom, __camZoom, 0.125);
	}

	// UNDO/REDO LOGIC
	#if REGION
	public inline function addToUndo(c:CharacterChange) {
		redoList = [];
		undoList.insert(0, c);
		while(undoList.length > Options.maxUndos)
			undoList.pop();
	}
	#end

	// TOP MENU OPTIONS
	#if REGION
	function _file_exit(_) {
		FlxG.switchState(new CharacterSelection());
	}

	function _file_new(_) {
	}

	function _file_save(_) {
	}

	function _file_saveas(_) {
	}

	function _edit_undo(_) {
		var v = undoList.shift();
		switch (v) {
			case null:
				// do nothing
			case CCreateAnim(animID, animData):
				deleteAnim(animData.name, false);
			case CEditAnim(name, oldData, animData):
				editAnim(name, oldData, false);
			case CDeleteAnim(animID, animData):
				createAnim(animData, animID, false);
			case CChangeOffset(name, change):
				changeOffset(name, change * -1, false);
			case CResetOffsets(oldOffsets):
				for (anim => offsets in oldOffsets)
					character.animOffsets.set(anim, offsets.clone());
			
				for (anim in character.getNameList())
					characterAnimsWindow.animButtons[anim].updateInfo(anim, character.getAnimOffset(anim), false);
				
				changeOffset(character.getAnimName(), FlxPoint.get(0, 0), false); // apply da new offsets
		}
		if (v != null)
			redoList.insert(0, v);
	}

	function _edit_redo(_) {
		var v = redoList.shift();
		switch (v) {
			case null:
				// do nothing
			case CCreateAnim(animID, animData):
				createAnim(animData, animID, false);
			case CEditAnim(name, oldData, animData):
				editAnim(oldData.name, animData, false);
			case CDeleteAnim(animID, animData):
				deleteAnim(animData.name, false);
			case CChangeOffset(name, change):
				changeOffset(name, change, false);
			case CResetOffsets(oldOffsets):
				clearOffsets(false);
		}
		if (v != null)
			undoList.insert(0, v);
	}

	function _char_add_anim(_) {
		createAnimWithUI();
	}

	function _char_edit_anim(_) {
		editAnimWithUI(character.getAnimName());
	}

	function _char_remove_anim(_) {
		deleteAnim(character.getAnimName());
	}

	function _char_edit_info(_) {
		FlxG.state.openSubState(new CharacterInfoScreen(character));
	}

	public function createAnimWithUI() {
		FlxG.state.openSubState(new CharacterAnimScreen(null, (_) -> {
			if (_ != null) createAnim(_);
		}));
	}

	public function editAnimWithUI(name:String) {
		FlxG.state.openSubState(new CharacterAnimScreen(character.animDatas.get(name), (_) -> {
			if (_ != null) editAnim(name, _);
		}));
	}

	public function createAnim(animData:AnimData, animID:Int = -1, addtoUndo:Bool = true) {
		XMLUtil.addAnimToSprite(character, animData);
		characterAnimsWindow.createNewButton(animData.name, FlxPoint.get(animData.x,animData.y), false, animID);

		playAnimation(animData.name);

		if (addtoUndo)
			addToUndo(CCreateAnim(character.getNameList().length, animData));
	}

	public function editAnim(name:String, animData:AnimData, addtoUndo:Bool = true) {
		var oldAnimData:AnimData = character.animDatas.get(name);
		var button:CharacterAnimButtons = characterAnimsWindow.animButtons[name];

		XMLUtil.addAnimToSprite(character, animData);
		button.updateInfo(animData.name, character.getAnimOffset(animData.name), false);

		if (character.getAnimName() == animData.name) // update anim ifs its currently selected
			playAnimation(animData.name);

		if (addtoUndo)
			addToUndo(CEditAnim(animData.name, oldAnimData, animData));
	}

	public function deleteAnim(name:String, addtoUndo:Bool = true) {
		if (character.getNameList().length-1 == 0)
			@:privateAccess character.animation._curAnim = null;
		else
			playAnimation(character.getNameList()[Std.int(Math.abs(character.getNameList().indexOf(name)-1))]);

		// undo shit blah blah
		var oldID:Int = character.getNameList().indexOf(name);
		var oldAnimData:AnimData = character.animDatas.get(name);

		character.removeAnimation(name);
		if (character.animOffsets.exists(name)) character.animOffsets.remove(name);
		if (character.animDatas.exists(name)) character.animDatas.remove(name);
		characterAnimsWindow.removeButton(name);

		if (addtoUndo)
			addToUndo(CDeleteAnim(oldID, oldAnimData));
	}

	public function editInfoWithUI(addtoUndo:Bool = true) {
		FlxG.state.openSubState(new CharacterInfoScreen(character));
	} 

	function _playback_play_anim(_) {
		if (character.getNameList().length != 0)
			playAnimation(character.getAnimName());
	}

	function _playback_stop_anim(_) {
		if (character.getNameList().length != 0)
			character.stopAnimation();
	}

	public function playAnimation(anim:String) {
		character.playAnim(anim, true);
		characterAnimsWindow.changeCurAnim(anim);
	}

	function _offsets_left(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(1, 0));
	}

	function _offsets_up(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(0, 1));
	} 

	function _offsets_down(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(0, -1));
	}

	function _offsets_right(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(-1, 0));
	}

	function _offsets_extra_left(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(5, 0));
	}

	function _offsets_extra_up(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(0, 5));
	} 

	function _offsets_extra_down(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(0, -5));
	}

	function _offsets_extra_right(_) {
		changeOffset(character.getAnimName(), FlxPoint.get(-5, 0));
	}

	function _offsets_clear(_) {
		clearOffsets();
	}

	function changeOffset(anim:String, change:FlxPoint, addtoUndo:Bool = true) {
		if (character.getNameList().length == 0) return;

		character.animOffsets.set(anim, character.getAnimOffset(anim) + change);
		characterAnimsWindow.animButtons[anim].updateInfo(anim, character.getAnimOffset(anim), false);
		character.frameOffset.set(character.getAnimOffset(anim).x, character.getAnimOffset(anim).y);

		if (addtoUndo)
			addToUndo(CChangeOffset(anim, change));
	}

	function clearOffsets(addtoUndo:Bool = true) {
		if (character.getNameList().length == 0) return;

		var oldOffsets:Map<String, FlxPoint> = [
			for (anim => offsets in character.animOffsets)
				anim => offsets.clone()
		];

		for (anim in character.getNameList()) {
			character.animOffsets[anim].zero();
			characterAnimsWindow.animButtons[anim].updateInfo(anim, character.getAnimOffset(anim), false);
		}

		if (addtoUndo)
			addToUndo(CResetOffsets(oldOffsets));
	}

	var zoom(default, set):Float = 0;
	var __camZoom(default, set):Float = 1;
	function set_zoom(val:Float) {
		return zoom = FlxMath.bound(val, -3.5, 1.75); // makes zooming not lag behind when continuing scrolling
	}
	function set___camZoom(val:Float) {
		return __camZoom = FlxMath.bound(val, 0.1, 3);
	}

	function _view_zoomin(_) {
		zoom += 0.25;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_zoomout(_) {
		zoom -= 0.25;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_zoomreset(_) {
		zoom = 0;
		__camZoom = Math.pow(2, zoom);
	}
	#end
}

enum CharacterChange {
	CCreateAnim(animID:Int, animData:AnimData);
	CEditAnim(name:String, oldData:AnimData, animData:AnimData);
	CDeleteAnim(animID:Int, animData:AnimData);
	CChangeOffset(name:String, change:FlxPoint);
	CResetOffsets(oldOffsets:Map<String, FlxPoint>);
}