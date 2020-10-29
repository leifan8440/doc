-- 部分不在文档的函数以及8.0之后的改动等
-- 想到什么写什么, 排版比较乱
--[[注意事项
    1. 游戏源生API不能直接使用盒子的对象, 要使用GUID, 比如 UnitExists(ThisUnit:GUID())
    2. Unit:Buff()等函数有缓存, 每次执行Rotation:Pulse()之前刷新, 关闭盒子调试时需要手动刷新,  AurasTable = {}
    3. 变量名, 作者名, 循环名等不能用数字开头, 不能含有特殊字符!
    4. 只有头部按指定格式的,同职业的自定义才会载入
    5. Rotation:Pulse()里不能删除Player:ReTarget 和 Rotations:RefreshUnitTables(), 前者有选球功能, 后者刷新缓存和Rotation:UnitTables()
    6. 盒子没用到的源生API, 自定义里使用需要加_G, 比如_G.IsLeftShiftKeyDown()
    7. 角色未选择专精时载入的循环始终为 Rotations[select(2, UnitClass("player"))]  (低等级角色)
    8. 种族技必须用指定的变量名定义才有 进攻性种族特长 这个选项
    Fireblood LightsJudgment BloodFury Berserking HyperOrganicLight BagOfTricks

]]


--[[函数
    1.获取单位的目标, 返回值为 GUID
    Unit:GetTarget()

    2.获取Spell施放成功后过去的时间, 根据UNIT_SPELLCAST_SUCCEEDED事件
    Spell:TimeSinceCastSuccess()

    3.获取Spell尝试施放后过去的时间, 在Unit:Cast(Spell)函数里更新的时间
    Spell:TimeSinceCast()

    注意 类似Spell:TimeSince...这种功能都需要先在Rotation:Initialize()定义好 比如 Blind = Spell(2094)
    
    3.在屏幕中显示信息
    function ScreenOverlay:Message(Message, FadingTime, y) -- 文字, 消失时间, y轴

    4.Unit:Buff Unit:BuffAny Unit:Debuff Unit:Aura 等等支持直接使用法术ID

    5. 增加判断debuff时间的参数 , Operator  ">" "<" "<=" ... 默认是 >
    function Unit:FilterEnemiesByDebuff(Table, Debuff, DebuffRemains, Operator) 

    6.新功能 根据生物ID过滤
    CreatureID = { [120651] = true, [122122] = true }
    function Unit:FilterEnemiesByCreatureID (Table, CreatureID)

    7.向角色面向的方向X码放技能
    function Player:CastGroundTo(Spell, Distance)

    8.增加参数NoCache,不使用缓存
    function Unit:EnemiesWithinDistance(Distance, PlayerCenteredAoE, BypassCCAndCombat, PlayerUnitsOnly, NoCache)

    9.新参数 BypassCCAndCombat, PlayerUnitsOnly, NoCache
    Unit:UnitsInFrontConeAroundUnit(Unit, Range, Angle, BypassCCAndCombat, PlayerUnitsOnly, NoCache)
    Unit:UnitsInFrontRectangle(Range, Width, Allies, AlliesHealth, BypassCCAndCombat, PlayerUnitsOnly, NoCache)
    Unit:UnitsInFrontCone(Range, Angle, Allies, AlliesHealth, BypassCCAndCombat, PlayerUnitsOnly, NoCache)

    10.Unit到给定Unit之间矩形范围的单位
    function Unit:UnitsInFrontRectangleAroundUnit(Unit, Range, Width, Allies, AlliesHealth, BypassCCAndCombat, PlayerUnitsOnly, NoCache)

    11.SelfEventsFrame:RegisterForEvent()
    使用RegisterUnitEvent(Event, "player") 为特定单位”player”注册事件,提高效率
    详见群文件的 盒子事件机制优化与改动.pdf

    12.Spell:IsLearned() 法术是否存在
    通过"SPELLS_CHANGED"事件触发,扫描天赋/技能书
    比Spell:Exists()更准确, 比如天赋技能B替换了原始技能A,但是技能A仍然Exists,或者技能B一直not Exists,还有战斗中会动态改变ID的技能,比如生存的野火炸弹,暗牧的虚空爆发/虚空箭等等
   
    13.全局的HardISCL, 这两个技能会先施法再引导,施法的时候GCD就转完了,导致接下来的引导过程被打断
    必须在HardISCL里加入, 以便施法时暂停循环
    HardISCL =  {
    [295258] = "聚能艾泽里特射线",
    [293491] = "回旋冲击波",}

    14. 驱散黑名单, CustomDispels
    -- Table for Custom Dispels.
    --@ debuff(SpellID): Debuff that we dont want to dispel
    --@ buffNeeded(SpellID): Buff on player that will cancel the ignore
    CustomDispels = {
    -- { debuff = 145206, buffNeeded = 642 } -- PG test - Debuff if not Divine Shield
    { debuff = 315176 }  --  贪婪触须 减速}

    15.Player:ForceCastGroundTowardUnit(Target, Spell, 距离, 重试次数);
    向角色面向Target的方向X码放技能


    16.Returns True if the unit should be dispelled
       @Types - An array of Types we want to cure ie: { "Poison", "Disease" } - Let it blanck for normal healers, use it for other specs as they cant use on magic.
    function Unit:CanDispel(Types, Offensive) -- 新参数功能 进攻驱散, Types除了术士法师以外都不需要传入了, 自动根据专精判断

    16.返回一个能驱散的Unit, 进攻驱散时返回血量最高的, 防御驱散返回血量百分比最低的
    Types除了术士法师以外都不需要传入了, 自动根据专精判断
    function Unit.Dispel (Table, Spell, Types, Offensive, PetDispel) -- 新参数功能 进攻驱散,是否宠物

    17. AddPresetOption("Cooldown", "使用精华", nil,nil,nil,"防御") -- 增加第6个参数, 加到哪一页

    18.function Spell:EssenceMinorEnabled() -- 精华的副能力是否启用, 没有返回false , 有返回等级

    19.物品使用黑名单 , 是法术ID,不是物品ID, 用select(2, GetItemSpell(ItemID))查看该物品的法术ID
    有如果你在循环里更新了这个表,要在之后运行一下AzeriteScan()刷新缓存
    HardBlacklistedItemSpellTable = {
    [299042] = true, -- 突触劫持电路 使用：心控目标机械生物  
    [288391] = true, -- 帕库冠羽 飞往附近的帕库图腾。只能在达萨罗的户外区域使用。
    }

    20.function Item:IsOptionEnabled() -- 该物品对应的饰品选项是否启用

    21.Player:UseTrinkets(APL)
    支持传入饰品的使用条件
    把表传入UseTrinkets, 如果要使用的饰品的ItemID在表中存在,那对应的判断函数成立才使用
    如果不存在那就用通用判断函数APL[0], 成立就使用
    或者没有传入任何参数,那就直接使用
    参数结构为
    APL = {
    [0] =  function ()  end, -- 通用判断函数,可以不存在
    [165572] = {[1] = function () return  Player:BuffCount(287916) == 6 end,}
    [165568] = {
                [1] = function()
                    return true
                end,
                TargetRequired = { -- TargetRequired可以不存在
                    [1] = true,
                    [2] = Focus -- 要使用的目标, 自行更新
                }
            }
    }

    22. Spell:FullRechargeTime() -- Spell到满层充能还要多久

    23. function UseTimer(timerName, interval)
    定时器, 每X秒执行一次 if UseTimer("test", 0.05) then print(GetTime()) end

    24. AddNewOption 增加一个类型 5 
    AddNewOption("高级设置", "自定义敌对黑名单列表", 250, false, {2, "忽略以下单位", {111, 222}}, nil, "启用后忽略列表中的敌对单位,格式必须是生物ID");
     {2, "忽略以下单位", {111, 222}}  -- 第一个数字表示类型, 1法术ID 2生物ID 3任何字符串, 如果纯数字那么类型为number , 第二个为标题, 第三个为默认值
     判断方法 GetOptionValue("自定义敌对黑名单列表")[Unit:CreatureID()]
    导入命令为/****  loadcil  选项名    如果是第2个设置项那就是 /****  loadcil 选项名 2

    25.重置某选项为默认值
    在Rotation:Initialize(), 最前面加入
    ResetOptions = { ["自动进入战斗"] = 20201023 }
    会把 自动进入战斗 重置为默认值一次
    下次还要重置, 把20201023改成20201024

    26. Rotation.Msg = "测试"
        Rotation.Msg 会加到帮助信息的最前面
        
    27. 显示可复制粘贴的的文本, 就是帮助信息那样的
    LibCopyPaste:Copy("帮助信息", "123456", { readOnly = true })

 ]]


 --[[
    部分有用的变量
    Rotations.CurrentUI 当前循环的专精ID
    CurrentRotation 当前循环的Table, 即那个Rotation:Pulse()的Rotation
    EncounterID  ENCOUNTER_START事件提供的Boss战ID
    RotationFileVersion  肥皂盒.dll的版本, 类型为字符串, 如果要比较那么要tonumber, 是local变量, 只能在自定义的代码里使用

    副本相关的:
    大秘境层数 C.InstanceLevel
    词缀 C.InstanceAffixes[1] [2] [3] [4] 第几个词缀
    2无常 3火山 4死疽 5繁盛 6暴怒 7激励 8血池 11崩裂 12重伤 13易爆 14震荡

    副本难度, 副本ID
    C.difficultyID, C.mapID

    是否在副本, 副本类型
    C.IsInInstance, C.InstanceType
 ]]

--[[ 
    自定义循环格式
    头尾不要有任何注释! 非常重要!
    循环头部必须是如下,  且在这一行之前不能有任何含有"SetRotation", "Rotation = "字样的注释!
    local Rotation = SetRotation(SpecID, Rotation, TitleName, ProfileID);

    SpecID 专精ID
    Rotation 循环
    TitleName 面板标题
    ProfileID 循环名和配置文件名  比如 1234 ,  配置文件名就是 恶魔猎手 - 浩劫 - 1234 - 默认.dat
    循环必须存在的部分
    function Rotation:Initialize()
    function Rotation:Events()
    function Rotation:Pulse()
    具体模板群文件有


    如果同职业多专精放到一个自定义里,那么第二个开始必须手动指定UUID
    
    -- 第一个
    local Rotation = SetRotation(102, {}, TitleName, ProfileID)
    function Rotation:Initialize()
    function Rotation:Events()
    function Rotation:Pulse()
    -- 第一个结束

    -- 第二个
    local Rotation = SetRotation(103, {UUID = 4643635435}, TitleName, ProfileID)
    function Rotation:Initialize()
    function Rotation:Events()
    function Rotation:Pulse()


     ]]

