extends Node3D

const WIDTH := 7.0
const CEILING := 8.0
const CHUNK := 14.0

var player: CharacterBody3D
var camera: Camera3D
var chunks: Array[Node3D] = []
var next_z := 10.0
var speed := 10.0
var score := 0.0
var crystals := 0
var lane := 0
var inverted := false
var running := false
var paused := false
var flip_lock := false
var best := 0

var cyan: StandardMaterial3D
var orange: StandardMaterial3D
var purple: StandardMaterial3D
var metal: StandardMaterial3D
var white: StandardMaterial3D
var hazard: StandardMaterial3D

var score_label: Label
var crystal_label: Label
var speed_label: Label
var gravity_label: Label
var menu: Control
var hud: Control
var pause_panel: Control
var gameover: Control
var info: Control

func _ready():
    randomize()
    _materials()
    _world()
    _ui()
    best = int(ProjectSettings.get_setting("application/config/best_score", 0))
    _show_menu()

func _materials():
    cyan = _mat(Color("#19dfff"), 4.0)
    orange = _mat(Color("#ff4b16"), 4.0)
    purple = _mat(Color("#bd39ff"), 5.0)
    metal = _mat(Color("#10162c"), 0.1)
    white = _mat(Color("#eaf7ff"), 1.5)
    hazard = _mat(Color("#ff163d"), 5.0)

func _mat(c: Color, emission: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = emission
    m.metallic = .65
    m.roughness = .25
    return m

func _world():
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("#02040e")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#18315e")
    e.ambient_light_energy = 0.8
    e.glow_enabled = true
    e.glow_intensity = 1.4
    e.fog_enabled = true
    e.fog_light_color = Color("#080b24")
    e.fog_density = 0.004
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.light_energy = 1.2
    sun.rotation_degrees = Vector3(-35,-25,0)
    add_child(sun)

    player = _make_player()
    add_child(player)
    player.position = Vector3(0,1.4,4)

    camera = Camera3D.new()
    camera.fov = 68
    camera.position = Vector3(0,5.2,-5)
    add_child(camera)
    camera.current = true

    for i in 55:
        var star := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = randf_range(.04,.16)
        mesh.height = mesh.radius*2
        star.mesh = mesh
        star.material_override = cyan if randf() > .5 else purple
        star.position = Vector3(randf_range(-45,45),randf_range(-35,35),randf_range(-30,260))
        add_child(star)

    for i in 18:
        _spawn_chunk()

func _make_player() -> CharacterBody3D:
    var p := CharacterBody3D.new()
    p.name = "Player"

    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = .45
    mesh.height = 1.8
    body.mesh = mesh
    body.material_override = white
    p.add_child(body)

    var visor := MeshInstance3D.new()
    var vm := BoxMesh.new()
    vm.size = Vector3(.48,.22,.08)
    visor.mesh = vm
    visor.material_override = cyan
    visor.position = Vector3(0,.15,.46)
    p.add_child(visor)

    var core := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = .22
    sm.height = .44
    core.mesh = sm
    core.material_override = orange
    core.position = Vector3(0,-.35,.35)
    p.add_child(core)

    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = .45
    shape.height = 1.8
    col.shape = shape
    p.add_child(col)
    return p

func _spawn_chunk():
    var z := next_z
    next_z += CHUNK
    var root := Node3D.new()
    root.name = "Chunk"
    add_child(root)
    chunks.append(root)

    _box(root, Vector3(0,0,z), Vector3(WIDTH,.65,CHUNK), metal)
    _box(root, Vector3(0,CEILING,z), Vector3(WIDTH,.65,CHUNK), metal)
    _box(root, Vector3(0,.38,z), Vector3(WIDTH+.1,.06,CHUNK), cyan)
    _box(root, Vector3(0,CEILING-.38,z), Vector3(WIDTH+.1,.06,CHUNK), orange)

    if randf() > .18:
        for i in randi_range(1,2):
            var x := randf_range(-2.6,2.6)
            var zz := z + randf_range(-4,4)
            var y := CEILING-.95 if randf() > .5 else .95
            _crystal(root, Vector3(x,y,zz))

    if randf() > .35:
        var x := randf_range(-2.7,2.7)
        var zz := z + randf_range(-4,4)
        var y := CEILING-1.15 if randf() > .5 else 1.15
        _hazard(root, Vector3(x,y,zz))

    if randf() > .72:
        var x := randf_range(-2.5,2.5)
        _box(root, Vector3(x,4,z+4), Vector3(.18,5,.25), purple)
        _sphere(root, Vector3(x,4,z+4), .55, purple)

func _box(parent, pos, scale, material):
    var b := StaticBody3D.new()
    parent.add_child(b)
    b.position = pos
    var mesh := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = scale
    mesh.mesh = bm
    mesh.material_override = material
    b.add_child(mesh)
    var c := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = scale
    c.shape = bs
    b.add_child(c)

func _sphere(parent, pos, radius, material):
    var s := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = radius
    sm.height = radius*2
    s.mesh = sm
    s.material_override = material
    s.position = pos
    parent.add_child(s)

func _crystal(parent, pos):
    var a := Area3D.new()
    a.position = pos
    parent.add_child(a)
    var mesh := MeshInstance3D.new()
    var sm := PrismMesh.new()
    sm.size = Vector3(.7,.7,.7)
    mesh.mesh = sm
    mesh.material_override = purple
    a.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(.8,.8,.8)
    col.shape = shape
    a.add_child(col)
    a.body_entered.connect(_collect.bind(a))

func _collect(body, area):
    if body == player:
        crystals += 1
        score += 25
        area.queue_free()

func _hazard(parent, pos):
    var a := Area3D.new()
    a.position = pos
    parent.add_child(a)
    var mesh := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0
    cm.bottom_radius = .75
    cm.height = 1.8
    mesh.mesh = cm
    mesh.material_override = hazard
    mesh.rotation_degrees = Vector3(0,0,45)
    a.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = .75
    shape.height = 1.8
    col.shape = shape
    a.add_child(col)
    a.body_entered.connect(_hit.bind(a))

func _hit(body, area):
    if body == player:
        _end()

func _ui():
    var layer := CanvasLayer.new()
    add_child(layer)

    menu = _panel(layer)
    _label(menu,"GRAVITY\nFLIP",100,Vector2(0,350),cyan)
    _label(menu,"FLIP GRAVITY. DEFY LIMITS.",28,Vector2(0,520),white)
    _button(menu,"PLAY",Vector2(0,700),StartRun)
    _button(menu,"INFO",Vector2(0,850),ShowInfo)

    hud = _panel(layer)
    score_label = _label(hud,"SCORE 0",34,Vector2(-330,90),white)
    crystal_label = _label(hud,"◆ 0",34,Vector2(330,90),purple)
    speed_label = _label(hud,"SPEED 10",24,Vector2(0,145),orange)
    gravity_label = _label(hud,"NORMAL GRAVITY",24,Vector2(0,1750),cyan)
    _button(hud,"◀",Vector2(150,1680),MoveLeft)
    _button(hud,"FLIP",Vector2(540,1680),Flip)
    _button(hud,"▶",Vector2(930,1680),MoveRight)
    _button(hud,"Ⅱ",Vector2(960,90),TogglePause)

    pause_panel = _panel(layer)
    _label(pause_panel,"PAUSED",70,Vector2(0,600),white)
    _button(pause_panel,"RESUME",Vector2(0,800),TogglePause)
    _button(pause_panel,"INFO",Vector2(0,950),ShowInfo)

    gameover = _panel(layer)
    _label(gameover,"RUN OVER",70,Vector2(0,560),orange)
    _label(gameover,"BEAT YOUR BEST",28,Vector2(0,680),white)
    _button(gameover,"RETRY",Vector2(0,850),StartRun)
    _button(gameover,"INFO",Vector2(0,1000),ShowInfo)

    info = _panel(layer)
    _label(info,"GRAVITY FLIP",64,Vector2(0,400),cyan)
    _label(info,"Flip gravity. Defy limits.\\n\\nA fast-paced 3D sci-fi runner.\\nSwitch between floor and ceiling,\\ndodge energy hazards and collect crystals.\\n\\nDESIGNED BY\\nTotcom Technologies",30,Vector2(0,820),white)
    _button(info,"CLOSE",Vector2(0,1450),HideInfo)

func _panel(layer):
    var p := ColorRect.new()
    p.color = Color(0.005,0.01,0.04,.94)
    p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(p)
    return p

func _label(parent,text,size,pos,color):
    var l:=Label.new()
    l.text=text
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",color)
    l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    l.position=pos-Vector2(450,100)
    l.size=Vector2(900,200)
    parent.add_child(l)
    return l

func _button(parent,text,pos,action):
    var b:=Button.new()
    b.text=text
    b.position=pos-Vector2(135,60)
    b.size=Vector2(270,120)
    b.add_theme_font_size_override("font_size",48)
    b.pressed.connect(action)
    parent.add_child(b)

func _show_menu():
    _hide_all(); menu.visible=true

func _hide_all():
    menu.visible=false; hud.visible=false; pause_panel.visible=false; gameover.visible=false; info.visible=false

func StartRun():
    _hide_all(); hud.visible=true
    score=0; crystals=0; speed=10; lane=0; inverted=false; paused=false; flip_lock=false
    player.position=Vector3(0,1.4,4); player.rotation=Vector3.ZERO; player.velocity=Vector3.ZERO
    running=true
    get_tree().paused=false

func TogglePause():
    if not running: return
    paused=!paused
    get_tree().paused=paused
    pause_panel.visible=paused

func MoveLeft(): lane=max(-1,lane-1)
func MoveRight(): lane=min(1,lane+1)

func Flip():
    if not running or paused or flip_lock:return
    flip_lock=true
    inverted=!inverted
    player.rotation.z += PI
    get_tree().create_timer(.22).timeout.connect(func(): flip_lock=false)

func ShowInfo(): info.visible=true
func HideInfo():
    info.visible=false
    if not running:_show_menu()

func _physics_process(delta):
    if not running or paused:return
    speed=min(30.0,speed+delta*.35)
    score+=speed*delta
    player.velocity=Vector3(0,(1 if inverted else -1)*24,speed)
    var target_x=lane*2.2
    player.position.x=lerp(player.position.x,target_x,delta*8)
    player.move_and_slide()

    camera.position=player.position+Vector3(0,5.2,-9)
    camera.look_at(player.position+Vector3(0,0,8))

    while player.position.z+100>next_z:_spawn_chunk()
    while chunks.size()>24:
        chunks[0].queue_free();chunks.pop_front()

    score_label.text="SCORE "+str(int(score))
    crystal_label.text="◆ "+str(crystals)
    speed_label.text="SPEED "+str(snapped(speed,.1))
    gravity_label.text="FLIPPED GRAVITY" if inverted else "NORMAL GRAVITY"

    if player.position.y < -4 or player.position.y > CEILING+4:_end()

func _unhandled_input(event):
    if event is InputEventKey and event.pressed:
        if event.is_action_pressed("flip"):Flip()
        if event.is_action_pressed("left"):MoveLeft()
        if event.is_action_pressed("right"):MoveRight()
    if event is InputEventScreenTouch and event.pressed:
        _touch_start=event.position
    if event is InputEventScreenTouch and not event.pressed:
        var d=event.position-_touch_start
        if abs(d.x)>80:
            if d.x<0:MoveLeft()
            else:MoveRight()
        else:Flip()

var _touch_start:=Vector2.ZERO

func _end():
    if not running:return
    running=false
    var final=int(score)
    if final>best:
        best=final
        ProjectSettings.set_setting("application/config/best_score",best)
    get_tree().paused=false
    _hide_all();gameover.visible=true
    _label(gameover,"SCORE "+str(final),42,Vector2(0,740),white)
