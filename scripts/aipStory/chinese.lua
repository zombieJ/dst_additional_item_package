return {
    -- 序言
    {
        name = "《序言》",
        desc = {
            "这本书的来历十分有趣，甚至有些传奇。作者长期受到妄想症的侵扰以至于难以分清现实与想象中的世界。在作者脑海中，存在着一个“永恒领域”，它存在着魔法与各种神奇生物。",
            "作者在这个想象的世界里畅游探险，制作各种物品以度过漫长的黑夜。而我们则可以通过这本书的只言片语了解到一些世界的特性，十分有趣。只可惜当年电子书不流行，换如今书中的插画如果会动就更赞了。",
            "当然，因为作者刻意使用了现实中消失的人名，这也引发了一些争议。认为这是对消失者的不尊重。但是从我的角度看，这本书已经足够优秀，并不需要这些作为噱头。相反，将现实与想象搞混更可能是作者的精神状况导致的问题。",
            "然而可惜的是，虽然这本书大获成功。但是作者却因为严重的精神问题而进了精神病院，据说又最终在某个月圆之夜从医院消失不见了。",
            "那么，亲爱的读者们。就好好欣赏这本书吧！",
        },
    },

    -- 引言
    {
        name = "一切的开头",
        desc = {
            "不知为何来到了这个世界，一些都有些不太一样。不过好在很快就适应了这里，相信一定有什么办法回到我原本的世界。在探索过程中，我还发现一些奇怪的东西。每当夜晚都会出现黑色的身影，它们似乎有着神奇的力量。但是当我伸手时，却又消失不见了。",
            "(一些污损的内容)",
            "这些鬼东西不知道是什么！火柴！我的火柴！！千万不要熄灭火柴！！！",
            "寂静的夜晚令人发狂，我在吃了一些白天收集的烤仙人掌后稍稍能够思考了。我要制作一些“额外物品”来保护自己，来应付接下来可能遇到的事情……",
        },
    },

    -- 武器
    {
        name = "酣战正欢",
        desc = {
            "这片奇艺的世界里，我需要一些武器来保护自己。这里充满了奇怪的物件，正好可以做一些尝试。",

            -- 玉米枪
            {
                type="img",
                name="popcorngun",
                -- atlas="images/inventoryimages/popcorngun.xml",
                -- image="popcorngun.tex",
            },
            "“玉米枪”只需要一些食材就能制作，可以远程攻击，在任何时候都非常好用。",

            -- 鱼刀
            {
                type="img",
                name="aip_fish_sword",
            },
            "用池塘里钓到的鱼制作的“鱼刀”虽然会腐烂，但是在海上却可以一直保持最佳的战斗效果倒也是让人惊喜~",

            -- 蜂语
            {
                type="img",
                name="aip_beehave",
            },
            "在沼泽地有一些奇怪的触手，用它们的触手钉制作的“蜂语”攻击蜂类生物似乎效果很不错。",

            -- 赌徒铠甲
            {
                type="img",
                name="aip_armor_gambler",
            },
            "在这个世界似乎有着奇怪的魔力，当你相信这件“赌徒铠甲”可以躲避致命伤害时，它似乎就有概率生效！",

            -- 诙谐面具
            {
                type="img",
                name="aip_joker_face",
            },
            "用活木制作的“诙谐面具”，总是时不时的会冒出火星并飞向附近的敌人。虽然耐久度不高，但是用活木可以直接修复也还算是耐用了。",
        
             -- 木图腾
            {
                type="img",
                name="woodener",
            },
            "“木图腾”可以存放一些木制品，比如树种、木材、活木什么的。它会每过一段时间就在附近种下树种。同时，它似乎也能将包容之物聚合成一根奇特的船桨。",
            
            -- 树精木浆
            {
                type="img",
                name="aip_oar_woodead",
            },
            "这把“树精木浆”就是那个神奇的船桨，不同于一般的船桨。每次划船反而会让它变得更结实。此外，用它攻击同一个敌人的时候也会越打越疼。真令人吃惊。",
       
            -- 子卿
            {
                type="img",
                name="aip_suwu",
            },
            "千山鸟飞绝，万径人踪灭。这把“子卿”正如其名，在人越少的时候会越强大！当永恒大陆没有其他人的时候，它就是你最强力的依仗。",
        
            
            -- 榴星
            {
                type="img",
                name="aip_oldone_durian",
            },
            "我尝试把“榴莲”和“球茎”结合后，它们产生了神奇的化学反应。可以像“球茎”一样投掷，但是却更耐用。我准备给它其名叫“‘榴’星”",
        },
    },

    -- 甘之如饴
    {
        name = "甘之如饴",
        desc = {
            "在这个世界探险，怎么可以少了我的独家秘方。事实证明无论是哪个世界，花蜜酿造的饮品都不会特别差~",

            -- 酿造桶
            {
                type="anim",
                build="aip_nectar_maker",
                anim="cooking",
                scale=.4,
                height=120,
                top=20,
            },

            "用一些木材做了一个简单的“花蜜酿造桶”后就可以开始酿造佳酿了。似乎不少东西都可以用来合成，甚至可以把酿造的花蜜继续酿造。不过每次酿造都会略微损失一些效果，也算是种平衡吧。当它过于强力时甚至可以持续恢复生命。我在酿造过程中也摸索出了一些技巧：",
            " - 冰块：食用后会降低体温",
            " - 水果：回复生命、理智、饥饿",
            " - 花蜜：回复生命、理智、饥饿",
            " - 蜂蜜：回复生命、理智、饥饿",
            " - 方糖：提升 1 级品质",
            " - 发光食物：回复理智值并提升移动速度",
            " - 食人花种子：攻击产生吸血效果",
            " - 蜂刺、蜘蛛巢、海象牙：提升攻击伤害",
            " - 粮食：花蜜过期后不会变成腐烂物而会变成酒饮",
            " - 点燃：可以提纯花蜜，有时候可以提升品质。当然，提纯只能提一次",

            -- 花蜜
            {
                type="img",
                name="aip_nectar_0",
            },
            "“糟糕品质的花蜜”真是我的失败之作。我在制作过程中一定混入了不可食用的恐怖东西！吃下感觉都不健康了。",

            {
                type="img",
                name="aip_nectar_1",
            },
            "人生的第一瓶可以饮用的花蜜往往都是“普通品质的花蜜”。",

            {
                type="img",
                name="aip_nectar_2",
            },
            "“优秀品质的花蜜”需要相当的精力，味道相当不错。",

            {
                type="img",
                name="aip_nectar_3",
            },
            "精益救精的酿造师才能制作出来的“精良品质的花蜜”，这是能力的证明！",

            {
                type="img",
                name="aip_nectar_4",
            },
            "“杰出品质的花蜜”相比饮用更值得收藏！",

            {
                type="img",
                name="aip_nectar_5",
            },
            "世上真的存在“完美品质的花蜜”吗？",

            {
                type="img",
                name="aip_nectar_wine",
            },
            "放了一些粮食的花蜜变质后不但没有腐坏，反而变成了“花蜜酒精饮”。只是喝下后走路有些不太稳当了。",
        },
    },

    -- 生存之道
    {
        name = "生存之道",
        desc = {
            "未雨绸缪总是首选，在战斗之前做一些补给准备会非常有用。",

            -- 酿造桶
            {
                type="img",
                name="aip_nectar_maker",
            },
            "“花蜜酿造桶”做的花蜜饮总是让人“甘之如饴”~",

            -- 血袋
            {
                type="img",
                name="aip_blood_package",
            },
            "“血袋”真是奇怪的东西，在原本的世界可不会因为喝一口它就能恢复健康，而在这里却可以？",

            -- 草木灰
            {
                type="img",
                name="aip_plaster",
            },
            "这里的夏天非常毒辣，在中暑的时候贴上一剂“草木灰”可以立刻缓解症状。",

            -- 古早沙滩壶
            {
                type="img",
                name="aip_olden_tea_half",
            },
            "我在海里捡到的瓶子里发现了这个配方，但是味道并不怎么样。喝下会有奇艺的感觉，好像鱼群都在说话似的。",

            -- 心悦锄
            {
                type="img",
                name="aip_xinyue_hoe",
            },
            "“心悦锄”是升级版的锄头，它可以直接放入9格种子，一锄头下去便会挖好9个坑并把种子种下。种下的植物都会非常高兴。",
        },
    },

    -- 魔力献祭
    {
        name = "魔力献祭",
        desc = {
            "永恒大陆充满着神秘的魔力，只要适当利用一些，就能获得强力的效果",

            -- 翡翠箱
            {
                type="img",
                name="aip_glass_chest",
            },
            "使用月光玻璃制作的“翡翠箱”会产生神奇的共振，在世界各地的箱子都会共用同一个容器。同时，它们也会和食人花、眼球草产生共振，偷取它们的所持之物。",
        
            -- 符文袋
            {
                type="img",
                name="aip_dou_inscription_package",
            },
            "“神秘权杖”的符文实在太多了，制作一个“符文袋”收纳它们是个不错的选择", 

            -- 西游人物卡
            {
                type="img",
                name="aip_xiyou_card_multiple",
            },
            "我不知道为什么这个世界也会有“西游人物卡”，收集齐全后可以合成一本强力的书籍。据我所知，击杀猪人、兔人、兔子、猴子、骨骸、鬼魂都有可能掉落卡牌。只是还有几种似乎只能靠“若光”给的盲盒抽奖得来？",

            -- 神话书说卡组
            {
                type="img",
                name="aip_xiyou_cards",
            },
            "当收集齐全部“西游人物卡”后合成而出的“神话书说卡组”有着奇艺的魔力，每次使用都可以直接对附近的暗影生物造成伤害。只是伤害总量似乎是一定的，多个暗影生物会分摊掉伤害。",
        },
    },

    -- 光鲜亮丽
    {
        name = "光鲜亮丽",
        desc = {
            "虽然世间充满无奈，但是我们还是要拼尽全力，把这个世界改造成更美好的世界。一件衣服、一顶帽子都会让生活变得有趣~",

            -- 马头
            {
                type="img",
                name="aip_horse_head",
            },
            "“马头”头套着实快乐，带着它的时候我甚至感觉自己跑起来都快了！~",

            -- 谜之声
            {
                type="img",
                name="aip_som",
            },
            "我把多余的“马头”扔进了“焚烧炉”后居然恶作剧般的给了我一个“谜之声”，穿戴后我和身边的人都变得更加理智了。",
        
            -- 岚色眼镜
            {
                type="img",
                name="aip_blue_glasses",
            },
            "用钢丝制作的“岚色眼镜”有着看透事物的本质。在目视之下，暗影生物看起来也只是普通的影子罢了。",
            
            -- 守财奴的背包
            {
                type="img",
                name="aip_krampus_plus",
            },
            "“守财奴的背包”就如掩耳盗铃的典故一般，虽然有着硕大的容量，但是每次被攻击都会掉落其中的一件物品。不过相对的，里面的东西越多，反而跑得越快也是很有意思。",
            
            -- 闹鬼巫师帽
            {
                type="img",
                name="aip_wizard_hat",
            },
            "在我击败“诙谐心脏”后得到了这顶“闹鬼巫师帽”，被暗影生物攻击时不再出现硬直。同时我也能更清晰的看到在地上漫步的诡异脚印了。",
        
            -- 鱼仔帽
            {
                type="img",
                name="aip_oldone_fisher",
            },
            "乌贼掉落的“鱼仔帽”似乎在其中“球茎”毒素的时候更加容易掉落。我发现穿戴之时，海钓的鱼线居然全然不会断裂。",
        },
    },

    -- 楼阁亭台
    {
        name = "楼阁亭台",
        desc = {
            "好吧，在这个世界想要做出好用的建筑看起来并不容易。",

            -- 焚烧炉
            {
                type="anim",
                build="incinerator",
                anim="consume",
                scale=.4,
                height=120,
            },
            "将多余的东西扔进“焚烧炉”付之一炬，得到的灰尘还能用来制作其他东西。真是一笔划算的买卖。",

            -- 贪婪观察者
            {
                type="anim",
                build="dark_observer",
                anim="spell_ing",
                scale=.25,
                height=120,
            },
            "不知道为什么我制作了这个“贪婪观察者”，它似乎能够更加清晰的看到世界的危险。只要给予金块就可以在地图上看到那些巨大的危险生物的位置。",
            
            -- 雪人小屋
            {
                type="anim",
                build="aip_igloo",
                anim="sleep_loop",
                scale=.3,
                height=120,
            },
            "用一些冰堆砌的“雪人小屋”在低温环境非常耐用，甚至可以做到永久使用。",
        },
    },

    -- 雕刻时光
    {
        name = "雕刻时光",
        desc = {
            "虽然不知道为什么，但是在这个世界我似乎非常有灵感。雕塑也是手到擒来。",

            -- 月光星尘
            {
                type="img",
                name="chesspiece_aip_moon",
            },
            "在一个夜晚，我以月光为引制作了“月光星尘”。结果它神奇的在晚上发出了微弱的月亮光芒。",

            -- 豆酱
            {
                type="img",
                name="chesspiece_aip_doujiang",
            },
            "“豆酱”是我们世界的漫画形象，我雕刻了它。",

            -- 守望者
            {
                type="img",
                name="chesspiece_aip_deer",
            },
            "“守望者”没什么特殊的地方，只是一头在等着什么的鹿而已。",

            -- 启迪时克雕塑
            {
                type="anim",
                build="aip_eye_box",
                scale=.2,
                height=210,
                top=-30,
            },
            "我不知道为什么，突然魔怔一般鬼斧神工的雕刻了这个“启迪时克”。似乎是有什么力量在驱使着我。每次看到这个雕塑，我的头就会疼得厉害，似乎耳边有什么东西在低语。一边给予我灵感，一边又使我痛苦。",

            -- 微笑
            {
                type="img",
                name="chesspiece_aip_mouth",
            },
            "“启迪时克雕塑”激发给我的灵感，“微笑”雕塑其实看着也并不是在微笑~",

            -- 章鱼
            {
                type="img",
                name="chesspiece_aip_octupus",
            },
            "“启迪时克雕塑”的另一个灵感，说实话我不知道为什么会雕刻出的“章鱼”有这么眼睛。",

            -- 美人鱼
            {
                type="img",
                name="chesspiece_aip_fish",
            },
            "“启迪时克雕塑”的又一灵感，呵，其实一点都不像“美人鱼”。",
        },
    },

    -- 神秘权杖
    {
        name = "神秘权杖",
        desc = {
            "这个世界的魔力流转太过复杂，我不得不收集一些树叶把我研究到的东西记录下来。通过一些材料组合，就可以制作出特定的符文。但是想要驱使这些符文还需要更为强大的控制力。",

            {
                type="img",
                name="aip_dou_opal",
            },
            "使用月光玻璃制作容器，再将一些道具放入其中后，会因为共振而结晶化成为“神秘猫眼石”。",

            {
                type="img",
                name="aip_dou_scepter",
            },
            "把它嵌入到“步行手杖”后就可以得到“神秘权杖”，用它就可以装载“符文”来驱使强大的魔力了。",

            {
                type="img",
                name="chesspiece_aip_doujiang_moonglass",
            },
            "在制作了多个容器后，我觉得都没什么趣味性。因而我雕刻了一个月光“豆酱”雕塑作为容器，不过做完后我就觉得这么好的作品，用来炼制猫眼石可就可惜了。",

            "（一些无关紧要的记录……）",

            {
                type="img",
                name="aip_leaf_note",
            },

            "因为我的疏忽，我的“树叶笔记”被大风刮走了。不过这也没有关系，我已经知道了我需要的所有东西。就让它们随风而去吧。",

            "某天我看到鸟儿叼来了我的“树叶笔记”，好吧。希望鸟儿们能把我的知识也带给其他人。",

            -- 赋能权杖
            {
                type="img",
                name="aip_dou_empower_scepter",
            },
            "在经过一系列调整后，“神秘权杖”可以得到额外的强化，但是它的强化方向极度不稳定，我无法选择让它强化成什么样子，都靠运气。但是在满月之下，它却总会强化成“月能”效果。",
        
            -- 游龙梦魇尾兽
            {
                type="anim",
                build="aip_dragon_tail",
                anim="walk_loop",
                scale=.5,
                height=80,
            },
            "该死，强化过的权杖被一只古怪的暗影生物破坏了。它吞下了权杖掉落的碎片就往“向日葵树林”飞走了。",

            -- 小麦
            {
                type="anim",
                build="aip_wheat",
                scale=.25,
                height=80,
            },
            "有一天我在采摘“干草”的时候，发现有一株变异了。它长得像现实世界的“小麦”，制膳也有着“粮食度”。有趣。",

            -- 向日葵
            {
                type="anim",
                build="aip_sunflower",
                bank="aip_sunflower",
                anim="idle_tall",
                scale=.25,
                height=200,
            },
            "每个季度变化，附近总会长出一株“向日葵树”。砍下会掉落1~2个向日葵，用来制作食物也有着“粮食度”。味道好极了。",
        
            -- 暗影生物脚印
            {
                type="anim",
                build="shadow_insanity1_basic",
                bank="shadowcreature1",
                anim="idle_loop",
                scale=.25,
                height=140,
                -- opacity=.9,
            },
            "在击败“暗影生物”的时候，有时候它们并没有真正死去。认真查看的话还会发现它们的脚印。当我十分理智的时候，这些脚印并不明显。",

            -- 变异向日葵
            {
                type="anim",
                build="aip_sunflower",
                anim="idle_ghost",
                scale=.25,
                height=200,
            },
            "当我追着这个脚印跑的时候，它逃到了“向日葵树”上，树瞬间变成了奇怪的样子。",

            -- 游龙梦魇
            {
                type="anim",
                build="aip_dragon",
                anim="walk_loop",
                scale=.5,
                height=200,
                left=-75,
            },
            "我试着砍伐这棵树，当它倒下之时从树中出现了那个弄坏我的权杖的家伙，我把它起名叫做“游龙梦魇”。我需要时克保持理智与其战斗，否则就会趁着我的荒神而造成巨大伤害。",

            -- 暗影碎牙
            {
                type="img",
                name="aip_dou_tooth",
            },
            "击败它后，我拿回了我的权杖配件。不知道的人会不会以为这是暗影怪的牙齿？",

            -- 噩梦之灵
            {
                type="anim",
                build="aip_nightmare_package",
                scale=.35,
                height=60,
            },
            "一起掉落的还有这个“噩梦之灵”，看着就有些不寒而栗。天知道为什么我会把它一口吃掉，感觉糟透了！",

            -- 闹鬼巫师帽
            {
                type="img",
                name="aip_wizard_hat",
            },
            "击败心脏后，我拿到了这顶“闹鬼巫师帽”。它让我可以更清晰的看到暗影足迹，真是一物降一物呐。",
        },
    },

    -- 诡影迷踪
    {
        name = "诡影迷踪",
        desc = {
            "我在月岛上收集月光玻璃的时候，发现这里的魔力扰动也有些不同寻常。这引起了我的兴趣。",

            -- 联结图腾
            {
                type="anim",
                build="aip_dou_totem",
                scale=.3,
                height=120,
            },

            "我在这里建造了一座“联结图腾”，来将这里的魔力为我所用。",

            -- 搬运石偶
            {
                type="img",
                name="aip_shadow_transfer",
            },
            "这个“搬运石偶”是我的得意之作。它可以直接标记建筑，并将它移动到新的地方。对于搬家而言还挺方便的。当然，得从鱼人那里借一些东西~",

            -- 月轨测量仪
            {
                type="img",
                name="aip_track_tool",
            },
            -- 玻璃矿车
            {
                type="img",
                name="aip_glass_minecar",
            },
            "通过“月轨测量仪”可以制作出能够跨越大海的轨道，配合“玻璃矿车”就可以实现跨海移动了。",

            -- 劣质的飞行图腾
            {
                type="anim",
                build="aip_fake_fly_totem",
                scale=.4,
                height=120,
            },
            "我尝试制作了一个“劣质的飞行图腾”来利用月岛的魔力，但是我发现单单使用它并不会生效，它需要至少多于一个才能工作。此外，如果不给“联结图腾”补充“噩梦燃料”魔力也是不够的。",

            -- 若光
            {
                type="anim",
                build="aip_mini_doujiang",
                anim="throw",
                scale=.5,
                height=80,
            },
            "我在“猪王”附近发现了一道时空裂隙，它将现实世界投射了过来。让我惊喜的是，原本漫画里的角色“若光”居然活生生的出现在了我的面前并且邀请我一同游玩。",

            -- 豆豆球
            {
                type="anim",
                build="aip_score_ball",
                anim="runRight",
                scale=.4,
                height=80,
            },
            "“若光”教我制作“豆豆球”和它玩拍球游戏。",

            -- 葡萄
            {
                type="img",
                name="aip_veggie_grape",
            },
            "打完球后，“若光”送了我一些“葡萄”解解口渴。它还提到，用“葡萄”制作的“葡果棒”是它最喜欢的食物，我下次给它带一些过来。",

            -- 劣质的飞行图腾
            {
                type="anim",
                build="aip_fly_totem",
                scale=.4,
                height=120,
            },
            "经过我的多次研究，我终于完成了纯粹消耗月岛魔力的“飞行图腾”，我在“若光”那里也装了一个，以后去做客就不需要走大老远啦。",

            -- 地图
            {
                type="img",
                name="aip_map",
            },
            "有一天，“若光”告诉我在海上有一个巨大的白色怪物，并且画了一幅“地图”给我。我准备改天去看看。",

            -- 饼干碎裂机
            {
                type="anim",
                build="aip_cookiecutter_king",
                scale=.2,
                height=250,
                top=120,
            },
            "它还真的是个巨大的家伙，如果那些小东西叫做“饼干切割机”，那这个就得叫“饼干碎裂机”了！它看到我的时候说了很多话，可是我一句都听不懂。后来我想起来之前的“古早沙滩壶”可以听懂鱼儿的声音就喝了一口。果然对它也是有效的。这个大家伙是个贪吃鬼，总是问我要一些吃的。不过我其实也挺闲的，就给他带来吧。",

            -- 饼干碎石
            {
                type="img",
                name="aip_shell_stone",
            },
            "不过这个家伙在海上实在难找，我就问他怎么确定它的位置。它给了我一些“饼干碎石”，说了句投石问路就离开了。",

            -- 泥蟹
            {
                type="anim",
                build="aip_mud_crab",
                anim="idle_loop",
                scale=.3,
                height=50,
            },
            "天呐，它居然想吃活“泥蟹”。这个小东西跑的比啥都快，连“陷阱”都抓不到它。不过好像“眼球草”可以抓住它们……",

            -- 子卿
            {
                type="img",
                name="aip_suwu",
            },
            "吃了不少东西后，“饼干碎裂机”打了一个饱嗝。掉出了一根叫“子卿”的树枝，但是我发现它威力无用。当你越孤单的时候，它就越强大。",

            -- 棱镜石
            {
                type="img",
                name="aip_legion",
            },
            "和“子卿”被一起打嗝掉出来的，还有这颗“棱镜石”。我看这个石头的尺寸，和之前在森林里看到的“魔力方阵”的插槽似乎大小相同。我得去试试。",

            -- 魔力方阵
            {
                type="anim",
                build="aip_rubik",
                scale=.3,
                height=120,
                top=30,
            },
            "我之前见到“魔力方阵”一直以为只是个大号的“梦魇灯座”，原来只是缺了最后一个部件。在我安装完“棱镜石”后，奇怪的事情发生了！",

            -- 诙谐之心
            {
                type="anim",
                build="aip_rubik_heart",
                scale=.3,
                height=130,
                top=-110,
            },
            "在“魔力方阵”上突然显现了一颗心脏，它如此有压迫感。",

            -- 诙谐梦魇
            {
                type="anim",
                build="aip_rubik_ghost",
                anim="idle_loop",
                scale=.25,
                height=150,
            },
            "当我回过神的时候，身边已经被这些暗影生物给围的严严实实了。更可怕的是，每击败一个怪物，其他的怪物就会变得更加强大，难缠极了。",

            -- 启迪时克雕塑
            {
                type="anim",
                build="aip_eye_box",
                scale=.2,
                height=210,
                top=-30,
            },
            "为了不再被“启迪时克雕塑”侵扰，我用“联结图腾”把它封印起来。但是以防万一哪天我还需要它，我设置了一个机关。当满月之夜，将这次冒险的“豆豆球”、“子卿”和“闹鬼巫师帽”放在“联结图腾”附近就能再次召唤出来。拜拜啦~",
        },
    },

    -- 古神低语
    {
        name = "古神低语",
        desc = {
            "前些日子为了找寻灵感，我再次一次释放了“启迪时克雕塑”。谁知道它出来的瞬间就逃跑了，根本来不及使用“月能强化过的神秘权杖”控制它。可恶，别让我抓到你！",

            -- 怪异的球茎
            {
                type="anim",
                build="aip_oldone_plant",
                anim="small",
                scale=.3,
                height=30,
                top=10,
            },
            "不知道是不是和“启迪时克雕塑”有关，这个世界出现了一些奇怪的变异。我在地面看到了一些“怪异的球茎”，如果要完整的采摘下来就需要使用“剃刀”。否则它破碎的脓液溅到身上会非常疼。",

            -- 拟态蜘蛛
            {
                type="anim",
                build="aip_oldone_rabbit",
                scale=.25,
                height=80,
            },
            "一天我在路上看到了一个像蜘蛛又像兔子的生物，我想看看它到底是哪儿来的。",

            -- 寄生蜘蛛巢
            {
                type="anim",
                build="aip_oldone_spiderden",
                scale=.4,
                height=180,
                top=25,
            },
            "跟着它们，我找到了源头。是一个“寄生蜘蛛巢”，看起来是那些“球茎”在蜘蛛巢尚且脆弱的时候寄生了进去。不过目前看来，似乎它们是无害的。",
        
            -- 袜子蛇
            {
                type="anim",
                build="aip_oldone_thestral",
                anim="idle_loop",
                scale=.25,
                height=80,
            },
            "在猪王身边，我看到了一个奇怪的身影，靠近发现是一条“袜子蛇”。说来有趣，这种莫名其妙的的生物我已经见怪不怪了。我还是研究一下“球茎”破掉的粘衣是不是可以做成料理来的实在。",

            -- 皮质果冻
            {
                type="img",
                name="aip_food_leather_jelly",
            },
            "完成了！这道“皮质果冻”晶莹剔透，吃起来也香糯可口。只是偶尔会看到一些奇怪的东西，应该没什么问题。哈哈哈哈哈！",

            -- 袜子蛇真身
            {
                type="anim",
                build="aip_oldone_thestral_full",
                anim="idle_loop",
                scale=.25,
                height=330,
            },
            "在吃下“皮质果冻”后，我一如往常找“猪王”换点金子。可是让我惊讶的是，原本的“袜子蛇”不见了。取而代之的是一个巨大的怪物！它能够通过我的嘴巴说话！当我听到了它的低语后，在哪里都会听到它的低语！我真是快要发疯了！",
        
            -- 污损的雕像
            {
                type="anim",
                build="aip_oldone_marble",
                scale=.25,
                height=200,
            },
            "我发现它非常讨厌有规律的锤击声，于是我在遥远的沼泽里做了一个大理石装置。它会定期锤击。耳朵灵敏的“袜子蛇”被这声音骚扰的心烦意乱，完全没有时间来管我了，让我继续探索这个世界吧。哈哈哈哈！",

            -- 漆黑的鹿
            {
                type="anim",
                build="aip_oldone_deer",
                anim="half",
                scale=.25,
                height=160,
            },
            "在地下我发现了一个长似鹿形的古怪石头，石头上布满了眼睛一样的纹理，似乎也是某种拟态生物。但是有些半死不活的样子。在经过一段时间调研后，我发现它其实是因为地下太过凉爽而失去了活性。于是我在它周围点了一些篝火，尝试帮它恢复活力。",
        
            -- 菇茑
            {
                type="anim",
                build="aip_oldone_deer_eye",
                scale=.35,
                height=50,
            },
            "在暖活起来后，石头边上长出了可口的“菇茑”。不过，似乎它也含有“球茎”的毒素，不能多吃。",
        },
    },

    -- 鲜花谜团
    {
        name = "鲜花谜团",
        desc = {
            "某一天我突然想起了我的世界的一款游戏，它里面有很多小型谜团，颇有趣味。我准备在这个世界也做一些谜团，让有缘人也来玩一玩。当然啦，是谜团肯定是有奖励的。只要有人解了谜团，我就会赋予解密者谜团因子，以便能在这个世界更好的生存下去~",

            -- 雪人
            {
                type="anim",
                build="aip_oldone_snowman",
                anim="snowman",
                scale=.25,
                height=200,
                loop=false,
            },
            "冬天最有趣的最莫过于堆雪人了，提前准备好一些大雪球后，很快就能堆起来。",

            -- 海荷叶
            {
                type="anim",
                build="aip_oldone_lotus_leaf",
                scale=.4,
                height=60,
                top=15,
            },
            "小时候，我很喜欢打水漂。我会用一些叶子围一个圈，和小伙伴们一起玩，看谁打得准。",

            -- 旺盛之树
            {
                type="anim",
                build="aip_oldone_tree",
                scale=.4,
                height=240,
            },
            "如果在树林之中，是否有人会发现有棵树不同寻常呢？哈哈哈，其实它是一个一次性的避雷针。",

            -- 瞬息全宇宙
            {
                type="anim",
                build="aip_oldone_once",
                anim="turn",
                loop=false,
                scale=.3,
                height=80,
            },
            "如果一块石头加上闪亮的眼睛，是不是就特别有趣呀？",

            -- 幕后黑手
            {
                type="anim",
                build="aip_oldone_black",
                scale=.35,
                height=80,
            },
            "我在附近藏了几个影子手掌，看看有没有人可以全部找到它们。",

            -- 搁浅水母
            {
                type="anim",
                build="aip_oldone_jellyfish",
                anim="dry",
                scale=.35,
                height=50,
            },
            "这只“搁浅水母”其实不是真的水母，而是我用粘衣仿制的。喂它一些海带就会变成可以保温的水母玩具。",

            -- 闹鬼陶罐
            {
                type="anim",
                build="aip_oldone_pot",
                scale=.35,
                height=70,
            },
            "这三个陶罐放在一起，任意破损都会马上恢复。看看谁可以在短时间内一起打破？",

            -- 盐洞
            {
                type="anim",
                build="aip_oldone_salt_hole",
                scale=.35,
                height=100,
                top=10,
            },
            "在海边的人们常吃盐渍鱼，推荐你们也尝尝。",

            -- 化缘石像
            {
                type="anim",
                build="aip_oldone_hot",
                scale=.25,
                height=80,
            },
            "夏天真是让人汗流浃背，吃一些冰饮更是最好不过了。",

            -- 
            {
                type="anim",
                build="aip_watering_flower",
                anim="withered",
                scale=.35,
                height=60,
            },
            "看到干枯的花朵，你会给它浇水么？",

            -- 古早花
            {
                type="anim",
                build="aip_four_flower",
                anim="open",
                scale=.35,
                height=50,
            },
            "一个小游戏，看看谁可以让所有的花都打开~",

            -- 固定的石头
            {
                type="anim",
                build="aip_oldone_rock",
                scale=.35,
                height=50,
            },
            "用石头围成一个圈并留一个缺口，把这个缺口补上吧。",

            -- 春日鲜花
            {
                type="anim",
                build="aip_oldone_plant_flower",
                scale=.25,
                height=100,
                top=40,
            },
            "地上一个小小的标记，种上一朵代表春天的花朵，迎来新的一天！",

            -- 落叶堆
            {
                type="anim",
                build="aip_oldone_leaves",
                scale=.35,
                height=60,
                top=10,
            },
            "点燃这堆落叶，把庭院打扫干净。",
        },
    },
}