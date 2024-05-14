package subStates;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import data.Conductor;
import data.GameData.MusicBeatSubState;
import gameObjects.hud.HealthIcon;
import gameObjects.hud.note.Strumline;
import gameObjects.hud.note.Note;
import gameObjects.menu.Alphabet;
import gameObjects.menu.options.OptionSelector;
import states.PlayState;

class OffsetsSubState extends MusicBeatSubState
{
    var strumline:Strumline;

    var downscroll:Bool = SaveData.data.get('Downscroll');
    var downMult:Int = 1;

    static var curSelected:Int = 0;
    var optionShit = ["Music Offset", "Input Offset", "Test Input"];
    var grpOptions:FlxTypedGroup<Alphabet>;
    var grpSelectors:FlxTypedGroup<OptionSelector>;

    var offsetCurBeat:Int = 0;
    var _offsetCurBeat:Int = 0;
    var crochet:Float = Conductor.calcBeat(85);
    var songPos:Float = Conductor.musicOffset;
    var offsetMusic:FlxSound;
    var testingInput:Bool = false;
    var countdown:Int = 0;
    var countdownSpr:Alphabet;

    var averageTxt:FlxText;
    var notesHit:Int = 0;
    var offsetAverage:Int = 0;

    var loopedTimes:Int = 0;

    public function new()
    {
        super();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        if(FlxG.sound.music != null)
            FlxG.sound.music.pause();
        offsetMusic = new FlxSound().loadEmbedded(Paths.music('settingOff'), true, false, function() {
            loopedTimes++;
        });
        offsetMusic.play();
        FlxG.sound.list.add(offsetMusic);

        downMult = downscroll ? -1 : 1;
        var bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
        bg.color = 0xFF1F0038;
        bg.screenCenter();
        add(bg);

        countdownSpr = new Alphabet(0, 0, "holyshit", true);
        countdownSpr.align = CENTER;
        countdownSpr.updateHitbox();
        countdownSpr.x = FlxG.width - FlxG.width / 4;
        countdownSpr.screenCenter(Y);
        add(countdownSpr);
        countdownSpr.text = "";

        averageTxt = new FlxText(0, 0, 0, "Holy Shit");
        averageTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, CENTER);
        averageTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
        averageTxt.y = (downscroll ? FlxG.height - averageTxt.height - 180 : 180);
        changeAverageTxt('');
        add(averageTxt);

        strumline = new Strumline(
            FlxG.width - FlxG.width / 4, null,
            downscroll,
            true, true, PlayState.assetModifier
        );
        add(strumline);

        grpOptions = new FlxTypedGroup<Alphabet>();
        var optionHeight:Float = (70 * 0.75) + 10;
        for(i in 0...optionShit.length)
        {
            var option = new Alphabet(60, 0, optionShit[i], true);
            option.scale.set(0.75,0.75);
            option.updateHitbox();
            option.ID = i;
            option.y = FlxG.height / 2 + (optionHeight * i);
            option.y -= (optionHeight * (optionShit.length / 2));
            grpOptions.add(option);
        }
        add(grpOptions);

        grpSelectors = new FlxTypedGroup<OptionSelector>();
        var mizera:Array<String> = ['Song Offset', 'Input Offset'];
        for(i in 0...2)
        {
            var daOption = grpOptions.members[i];
            var selector = new OptionSelector(SaveData.data.get(mizera[i]), false);
            selector.options = SaveData.displaySettings.get(mizera[i])[3];
            selector.wrapValue = false;
            selector.setY(daOption.y + optionHeight / 2);
            selector.setX(daOption.x + 450);
            selector.ID = i;
            grpSelectors.add(selector);
        }
        add(grpSelectors);

        changeOption();
        offsetBeatHit();
    }

    function changeAverageTxt(newText:String)
    {
        averageTxt.text = newText;
        averageTxt.x = FlxG.width - FlxG.width / 4 - averageTxt.width / 2;
    }

    function changeOption(change:Int = 0)
    {
        if(change != 0) FlxG.sound.play(Paths.sound('menu/scrollMenu'));

        curSelected += change;
        curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);

        for(item in grpOptions.members)
        {
            item.alpha = 0.4;
            if(item.ID == curSelected && !testingInput)
                item.alpha = 1.0;
        }
        for(selec in grpSelectors.members)
        for(item in [selec.arrowL, selec.text, selec.arrowR])
        {
            item.alpha = 0.4;
            if(selec.ID == curSelected)
                item.alpha = 1.0;
        }
    }

    var holdTimer:Float = 0;

    function changeSelector(change:Int = 0)
    {
        if(change != 0 && holdTimer < 0.5)
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
        
        var selector = grpSelectors.members[curSelected];
        selector.changeSelection(change);
        selector.setX(grpOptions.members[selector.ID].x + 450);

        SaveData.data.set(['Song Offset','Input Offset'][curSelected], grpSelectors.members[curSelected].value);
        SaveData.save();

        if(curSelected == 0)
        {
            songPos += change;
            if(PlayState.instance != null)
                PlayState.instance.updateOption('Song Offset');
        }
    }

    function offsetBeatHit()
    {
        cameras[0].zoom = 1.025; // 1.05, 1.025
        //trace("hello " + offsetCurBeat);
        if(testingInput && countdown <= 4)
        {
            countdownSpr.text = ["3","2","1","GO",""][countdown];
            countdown++;
        }

        var rawOffsetMusicTime:Float = offsetMusic.time + (offsetMusic.length * loopedTimes);
        var realOffsetMusicTime:Float = rawOffsetMusicTime + Conductor.musicOffset;
        if(Math.abs(songPos - realOffsetMusicTime) >= 20)
        {
            trace('synced $songPos to $realOffsetMusicTime');
            songPos = realOffsetMusicTime;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        songPos += elapsed * 1000;
        _offsetCurBeat = Math.floor(songPos / crochet);
        while(_offsetCurBeat != offsetCurBeat)
        {
            if(_offsetCurBeat > offsetCurBeat)
                offsetCurBeat++;
            else
                offsetCurBeat = _offsetCurBeat;
            offsetBeatHit();
        }

        var pressed:Array<Bool> = [
            Controls.pressed("LEFT"),
            Controls.pressed("DOWN"),
            Controls.pressed("UP"),
            Controls.pressed("RIGHT"),
        ];
        var justPressed:Array<Bool> = [
            Controls.justPressed("LEFT"),
            Controls.justPressed("DOWN"),
            Controls.justPressed("UP"),
            Controls.justPressed("RIGHT"),
        ];

        cameras[0].zoom = FlxMath.lerp(cameras[0].zoom, 1.0, elapsed * 6);
        
        if(!testingInput)
        {
            if(Controls.justPressed("BACK"))
            {
                cameras[0].zoom = 1.0;
                offsetMusic.stop();
                if(FlxG.sound.music != null)
                    FlxG.sound.music.play();
                close();
            }
        
            if(Controls.justPressed("UI_UP"))
                changeOption(-1);
            if(Controls.justPressed("UI_DOWN"))
                changeOption(1);
        
            if(curSelected != 2)
            {
                if(Controls.justPressed("UI_LEFT")) {
                    holdTimer = 0;
                    changeSelector(-1);
                }
                if(Controls.justPressed("UI_RIGHT")) {
                    holdTimer = 0;
                    changeSelector(1);
                }
                if(Controls.pressed("UI_LEFT") || Controls.pressed("UI_RIGHT"))
                    holdTimer += elapsed;
                else
                    holdTimer = 0;
        
                if(holdTimer >= 0.5)
                {
                    function toInt(bool:Bool):Int
                        return bool ? 1 : 0;
                    changeSelector(toInt(Controls.pressed("UI_RIGHT"))-toInt(Controls.pressed("UI_LEFT")));
                }
            }
            else if(Controls.justPressed("ACCEPT"))
            {
                trace('started testing!!');
                testingInput = true;
                changeOption();
                countdown = 0;
                notesHit = 0;
                offsetAverage = 0;
                changeAverageTxt('');
                for(i in 0...4)
                {
                    var note = new Note();
                    note.updateData(
                        (Math.floor(songPos / crochet) * crochet) + crochet * (i + 5),
                        i, (i == 3) ? "end_test" : "none", PlayState.assetModifier
                    );
                    note.reloadSprite();
                    strumline.addNote(note);
                    note.x -= 1000;
                }
            }
        }
        else
        {
            for(note in strumline.allNotes)
            {
                note.updateHitbox();
                note.offset.x += note.frameWidth * note.scale.x / 2;
                note.offset.y += note.frameHeight * note.scale.y / 2;
                var thisStrum = strumline.strumGroup.members[note.noteData];
                
                // follows the strum
                var offsetX = note.noteOffset.x;
                var offsetY = (note.songTime - songPos) * (strumline.scrollSpeed * 0.45);
                
                var noteAngle:Float = (note.noteAngle + thisStrum.strumAngle);
                if(strumline.downscroll)
                    noteAngle += 180;
                
                note.angle = thisStrum.angle;
                CoolUtil.setNotePos(note, thisStrum, noteAngle, offsetX, offsetY);

                if(justPressed.contains(true))
                {
                    if(Math.abs(note.songTime - songPos) <= 100
                    && justPressed[note.noteData]
                    && note.visible)
                    {
                        thisStrum.playAnim("confirm");
                        note.visible = false;
                        notesHit++;
                        var noteDiff:Int = Math.floor(note.songTime - songPos);
                        offsetAverage += noteDiff;
                        changeAverageTxt('${noteDiff}ms');
                    }
                }
                if(note.noteType == "end_test")
                {
                    if(note.songTime - songPos <= -100 || !note.visible)
                    {
                        trace('ended');
                        testingInput = false;
                        if(notesHit != 0) {
                            offsetAverage = Math.floor(offsetAverage / notesHit);
                            changeAverageTxt('Recommended Input Offset: ${-offsetAverage}ms');
                        } else {
                            changeAverageTxt('No Notes Hit');
                        }
                        
                        changeOption();
                    }
                }
            }
            if(!testingInput)
            {
                for(note in strumline.allNotes)
                    strumline.removeNote(note);
            }
        }
        
        for(strum in strumline.strumGroup)
		{
            if(testingInput)
            {
                if(pressed[strum.strumData])
                {
                    if(!["pressed", "confirm"].contains(strum.animation.curAnim.name))
                        strum.playAnim("pressed");
                }
                else
                    strum.playAnim("static");
            }
            else
            {
                if(strum.animation.curAnim.name != "static"
                && strum.animation.curAnim.finished)
                    strum.playAnim("static");
            }
		}
    }
}