local petConfig = require("configurations/aip_pet")
local PET_QUALITY_COLORS = petConfig.QUALITY_COLORS

return {
    -- 序言
    {
        name = "'Preface'",
        desc = {
            "NOTE: This article is translated by Google Translate. Please feel free to volunteer for translateing.",

            "",

            "The origin of this book is very interesting, even a bit legendary. The author has been plagued by paranoia for so long that it is difficult to distinguish the real and imagined worlds. In the author's mind, there is an 'eternal realm' in which magic and various A magical creature.",
            "The author travels and explores in this imaginary world, making various objects to spend the long night. And we can learn some of the characteristics of the world through the few words of this book, which is very interesting. It's a pity that e-books were not popular in those days. It would be even better if the illustrations in the book could move.",
            "Of course, because the author deliberately used the names of people who disappeared in reality, it also caused some controversy. I think it is disrespectful to the disappeared. But from my point of view, this book is good enough that it does not need these acts. A gimmick. Instead, confusing reality with imagination is more likely to be a problem with the author's mental state.",
            "Unfortunately, although the book was a great success, the author was admitted to a mental hospital because of serious mental problems, and it is said that he eventually disappeared from the hospital on a full moon night.",
            "Then, dear readers. Enjoy this book!",
        },
    },

    -- 引言
    {
        name = "The Beginning",
        desc = {
            "I don't know why I came to this world, and some of them are a little different. But fortunately, I quickly adapted to this world, and I believe there must be some way to return to my original world. During the exploration process, I also found some strange things. Black figures appear every night, they seem to have magical powers. But when I reach out, they disappear.",
             "(some defaced content)",
             "I don't know what these ghosts are! Matches! My matches!! Never put out matches!!!",
             "The silent night is maddening and I'm able to think for a while after eating some roasted cacti I collected during the day. I'm going to make some 'extras' to protect myself from what may come next...",
        },
    },

    -- 武器
    {
        name = "Go Fighting",
        desc = {
            "In this strange world, I need some weapons to protect myself. It's full of strange objects, and it's time to try something.",

            -- 玉米枪
            {
                type="img",
                name="popcorngun",
            },
            "The 'Corn Gun' can be crafted with just a few ingredients, can attack from a distance, and is very useful at any time.",

            -- 鱼刀
            {
                type="img",
                name="aip_fish_sword",
            },
            "Although the 'Fish Swprd' made from fish caught in the pond will rot, it is amazing that it can always maintain the best fighting effect at sea~",

            -- 蜂语
            {
                type="img",
                name="aip_beehave",
            },
            "There are some strange tentacles in the swamp that seem to work pretty well against bees with their 'bee whispers' made from their tentacle spikes.",

            -- 赌徒铠甲
            {
                type="img",
                name="aip_armor_gambler",
            },
            "There seems to be a strange magic in this world. When you believe that this \"Gambler's Armor\" can avoid fatal damage, it seems to have a chance to work!",

            -- 诙谐面具
            {
                type="img",
                name="aip_joker_face",
            },
            "The 'joke mask' made of living wood always pops up sparks from time to time and flies to nearby enemies. Although the durability is not high, it is still durable if it can be directly repaired with living wood.",
        
             -- 木图腾
            {
                type="img",
                name="woodener",
            },
            "The 'Wood Totem' can store some wood products, such as tree species, wood, living wood, etc. It will plant tree species nearby every once in a while. At the same time, it also seems to be able to aggregate the inclusions into a strange boat paddle.",

            -- 树精木浆
            {
                type="img",
                name="aip_oar_woodead",
            },
            "This 'tree pulp' is that magical oar, different from ordinary oars. Every time you row the boat, it will make it stronger. Also, it will hurt more and more when you use it to attack the same enemy .It's amazing.",

            -- 子卿
            {
                type="img",
                name="aip_suwu",
            },
            "Thousands of mountains and birds fly away, and thousands of people disappear. This 'Ziqing' is just like its name, it will be stronger when there are fewer people! When there are no other people in the Eternal Continent, it is your strongest support .",

            -- 榴星
            {
                type="img",
                name="aip_oldone_durian",
            },
            "I tried to combine 'Durian' and 'Bulb', they have a magical chemical reaction. Can be thrown like 'Bulb', but more durable. I'm going to give it another name \"'Durian' Star\"",
        
            -- 弹跳符
            {
                type="img",
                name="aip_jump_paper",
            },
            "Rice Amulet can jump between enemies once. Same as boomerang, do not get hurt when it returns.",
        
            -- 蜂刺吹箭
            {
                type="img",
                name="aip_blowdart",
            },
            "Blow darts with Stinger as ammunition, can be used multiple times, but the damage is not high.",
        },
    },

    -- 甘之如饴
    {
        name = "Nice Drink",
        desc = {
            "Exploring in this world, how can I not have my exclusive secret recipe. It turns out that no matter which world it is, the drinks brewed with nectar are not particularly bad~",

            -- 酿造桶
            {
                type="anim",
                build="aip_nectar_maker",
                anim="cooking",
                scale=.4,
                height=120,
                top=20,
            },

            "After making a simple 'nectar brewing barrel' with some wood, you can start brewing good wine. It seems that many things can be used to craft, and even the brewed nectar can be continued to brew. However, each brew will lose some effect , it's kind of a balance. When it's too powerful, it can even continue to regenerate life. I also figured out some tricks during the brewing process:",
             " - Ice cubes: lowers body temperature when eaten",
             " - Fruit: Restores Health, Sanity, Hunger",
             " - Nectar: Restores Health, Sanity, Hunger",
             " - Honey: Restores Health, Sanity, Hunger",
             " - Sugar cubes: 1 level higher quality",
             " - Glowing Food: Restores Sanity and increases Movement Speed",
             " - Piranha Seeds: Attacks inflict lifesteal effects",
             " - Bee Stinger, Spider Nest, Walrus Tusk: increased attack damage",
             " - Food: After nectar expires, it does not turn into rot and turns into booze",
             " - Burn: Burns the nectar will increase little quality, but it can only purify once",

            -- 花蜜
            {
                type="img",
                name="aip_nectar_0",
            },
            "The 'bad quality nectar' is a real failure of mine. I must have mixed in some inedible horror in the making! It doesn't feel healthy to eat.",

            {
                type="img",
                name="aip_nectar_1",
            },
            "The first drinkable nectar in one's life is often 'normal quality nectar'.",

            {
                type="img",
                name="aip_nectar_2",
            },
            "'Excellent quality nectar' requires considerable effort and tastes quite good.",

            {
                type="img",
                name="aip_nectar_3",
            },
            "The 'fine quality nectar' that can only be produced by lean brewers, this is proof of ability!",

            {
                type="img",
                name="aip_nectar_4",
            },
            "'Nectar of outstanding quality' is more collectible than drinking!",

            {
                type="img",
                name="aip_nectar_5",
            },
            "Is there really a 'perfect quality nectar'?",

            {
                type="img",
                name="aip_nectar_wine",
            },
            "After the nectar with some grains has deteriorated, not only did it not spoil, but it became a 'nectar alcohol drink'. It's just that walking is a little unstable after drinking it.",
        },
    },

    -- 生存之道
    {
        name = "Survival",
        desc = {
            "A rainy day is always preferred, and it can be very useful to prepare some supplies before a fight.",

            -- 酿造桶
            {
                type="img",
                name="aip_nectar_maker",
            },
            "The nectar drink made by the 'nectar brewing barrel' always makes people 'sweet'~",

            -- 血袋
            {
                type="img",
                name="aip_blood_package",
            },
            "The 'Blood Package' is really a strange thing. In the original world, it would not restore health by taking a sip of it, but here it can?",

            -- 草木灰
            {
                type="img",
                name="aip_plaster",
            },
            "Summer here is very nasty, and putting on a dose of 'Plaster' during heatstroke can immediately relieve symptoms.",

            -- 古早沙滩壶
            {
                type="img",
                name="aip_olden_tea_half",
            },
            "I found this recipe in a bottle I found in the sea, but it didn't taste very good. Drinking it will feel like a strange art, as if the fish are talking.",

            -- 明目药膏
            {
                type="img",
                name="aip_fig_salve",
            },
            "'Fig Salve' is absorbed through the face for treatment, so if it is used continuously before the absorption is complete, the effect will become poor. At the same time, it also allows me to observe the quality of small animals more clearly.",

            -- 心悦锄
            {
                type="img",
                name="aip_xinyue_hoe",
            },
            "'Xinyue Hoe' is an upgraded version of the hoe. It can directly put 9 seeds into it. When the hoe goes down, it will dig 9 holes and plant the seeds. Plants will be very happy.",
        },
    },

    -- 魔力献祭
    {
        name = "Magic First",
        desc = {
            "The Eternal Continent is full of mysterious magic, as long as you use it properly, you can get powerful effects",

            -- 翡翠箱
            {
                type="img",
                name="aip_glass_chest",
            },
            "The 'emerald chest' made of moonlight glass will have a magical resonance, and chests all over the world will share the same container. At the same time, they will also resonate with piranhas and eye grasses, stealing what they hold." ,

            -- 符文袋
            {
                type="img",
                name="aip_dou_inscription_package",
            },
            "There are too many runes in 'Mystic Scepter', making a 'Rune Bag' to store them is a good choice",

            -- 西游人物卡
            {
                type="img",
                name="aip_xiyou_card_multiple",
            },
            "I don't know why there are 'Journey to the West character cards' in this world. After collecting them, they can be combined into a powerful book. As far as I know, it is possible to kill pigmen, bunnymen, rabbits, monkeys, bones, and ghosts Drop cards. But there are a few more that seem to be obtained only by the blind box lottery given by 'Ruoguang'?",

            -- 神话书说卡组
            {
                type="img",
                name="aip_xiyou_cards",
            },
            "When all the 'Journey to the West Character Cards' are collected and synthesized, the 'Myth Book' has magical power, and each time it is used, it can directly cause damage to nearby shadow creatures. The total amount of damage seems to be certain. , multiple shadow creatures will split the damage.",
        },
    },

    -- 光鲜亮丽
    {
        name = "Wonderful Dress",
        desc = {
            "Although the world is full of helplessness, we still have to do our best to transform this world into a better world. A dress and a hat will make life more interesting~",

            -- 马头
            {
                type="img",
                name="aip_horse_head",
            },
            "The 'horse head' headgear is really happy, I even feel like I run faster when I wear it!~",

            -- 谜之声
            {
                type="img",
                name="aip_som",
            },
            "I threw the extra 'horse head' into the 'burner' and actually gave me a 'mystery voice' as a prank. After wearing it, I and the people around me became more rational.",
        
            -- 岚色眼镜
            {
                type="img",
                name="aip_blue_glasses",
            },
            "The 'Lan-colored glasses' made of steel wire have the essence of seeing things through. Under the eyes, the shadow creatures look like ordinary shadows.",
            
            -- 守财奴的背包
            {
                type="img",
                name="aip_krampus_plus",
            },
            "The Scrooge's Backpack is like the allusion to stealing a bell. Although it has a huge capacity, it will drop one of the items every time it is attacked. But on the contrary, the more things inside, the faster it runs. interesting.",
            
            -- 闹鬼巫师帽
            {
                type="img",
                name="aip_wizard_hat",
            },
            "I got this \"Haunted Wizard's Hat\" after defeating 'Witty Heart', and it no longer appears stiff when attacked by shadow creatures. At the same time, I can also see the strange footprints walking on the ground more clearly.",
        
            -- 鱼仔帽
            {
                type="img",
                name="aip_oldone_fisher",
            },
            "The 'Fisher Hat' dropped by the squid seems to be more likely to fall when the 'bulb' toxin is in it. I found that when wearing it, the fishing line for sea fishing did not break at all.",
        
            -- 鲨渔帽
            {
                type="img",
                name="aip_xiaoyu_hat",
            },
            "I got this from Shark. It will help reduce damage on the ocean and take bullkelp directly.",
        },
    },

    -- 楼阁亭台
    {
        name = "Strcutrue It",
        desc = {
            "Well, it doesn't seem easy to make useful buildings in this world.",

            -- 焚烧炉
            {
                type="anim",
                build="incinerator",
                anim="consume",
                scale=.4,
                height=120,
            },
            "Toss the excess in the 'burner' and burn it down, and the dust can be used to make other things. It's a good deal.",

            -- 垃圾堆
            {
                type="anim",
                build="aip_garbage_dump",
                anim="place",
                scale=.6,
                height=90,
            },
            "'garbage dump' will return nothing. But when full, will get 'bezoar' after burning for a while and then extinguishing.",

            -- 贪婪观察者
            {
                type="anim",
                build="dark_observer",
                anim="spell_ing",
                scale=.25,
                height=120,
            },
            "I don't know why I made this 'greedy watcher', it seems to be able to see the dangers of the world more clearly. Just give gold nuggets to see the location of those huge dangerous creatures on the map.",
            
            -- 雪人小屋
            {
                type="anim",
                build="aip_igloo",
                anim="sleep_loop",
                scale=.3,
                height=120,
            },
            "A 'snowman hut' made of some ice is very durable at low temperatures and can even last forever.",

            -- 展示柜
            {
                type="anim",
                build="aip_showcase",
                anim="stone",
                scale=.3,
                height=90,
            },
            "Put something to show on the showcase, but it do not prevent perish. Can change style by pickaxe with one time.",
        
            -- 冰展示柜
            {
            type="anim",
            build="aip_showcase",
            anim="ice_mix",
            scale=.3,
            height=90,
            },
            "Of course. Ice one can keep fresh. Also workable with pickaxe.",

            -- 武器库
            {
                type="anim",
                build="aip_weapon_box",
                anim="idle",
                scale=.3,
                height=90,
            },
            "I can perceive the life of this box. After establishing a connection with it, the box will send me the same kind of tools that I just used up.",
        },
    },

    -- 雕刻时光
    {
        name = "Carving Time",
        desc = {
            "I don't know why, but I seem to be very inspired in this world. Sculpture is also within my grasp.",

            -- 月光星尘
            {
                type="img",
                name="chesspiece_aip_moon",
            },
            "One night, I made 'Moonlight Stardust' using moonlight as a reference. It turned out to magically emit a faint moonlight at night.",

            -- 豆酱
            {
                type="img",
                name="chesspiece_aip_doujiang",
            },
            "'Dou Jiang' is a cartoon image of our world, I sculpted it.",

            -- 守望者
            {
                type="img",
                name="chesspiece_aip_deer",
            },
            "The Watcher is nothing special, just a deer waiting for something.",

            -- 启迪时克雕塑
            {
                type="anim",
                build="aip_eye_box",
                scale=.2,
                height=210,
                top=-30,
            },
            "I don't know why, but I suddenly sculpted this 'Enlightenment Shik' like magic. It seems that some force is driving me. Every time I see this sculpture, my head hurts so badly Something is whispering. It inspires me and pains me at the same time.",

            -- 微笑
            {
                type="img",
                name="chesspiece_aip_mouth",
            },
            "The 'Enlightenment Sculpture' inspired me, the 'Smile' sculpture actually doesn't look like a smile~",

            -- 章鱼
            {
                type="img",
                name="chesspiece_aip_octupus",
            },
            "Another inspiration for 'Enlightenment Sculpture', I honestly don't know why the 'octopus' has such eyes.",

            -- 美人鱼
            {
                type="img",
                name="chesspiece_aip_fish",
            },
            "Another inspiration for 'Enlightenment Sculpture', oh, it doesn't look like a 'mermaid' at all.",
        },
    },

    -- 神秘权杖
    {
        name = "Mystic Scepter",
        desc = {
            "The flow of magic in this world is too complicated, and I had to collect some leaves to record what I researched. With some combination of materials, specific runes can be made. But to drive these runes requires more Great control.",

            {
                type="img",
                name="aip_dou_opal",
            },
            "Use moonlight glass to make a container, and put some props into it, it will crystallize into a 'mysterious opal' due to resonance.",

            {
                type="img",
                name="aip_dou_scepter",
            },
            "Embed it into the 'Walking Cane' to get the 'Mystic Scepter', and use it to load 'Runes' to drive powerful magic.",

            {
                type="img",
                name="chesspiece_aip_doujiang_moonglass",
            },
            "After I made several containers, I didn't think it was interesting. So I carved a moonlight 'Dou Jiang' sculpture as a container, but after I finished it, I thought it was such a good work, it can be used to make opals Pity.",

             "(some insignificant records...)",

            {
                type="img",
                name="aip_leaf_note",
            },

            "My 'leaf notes' were blown away by the wind because of my negligence. But that's okay, I already know everything I need. Just let them go with the wind.",

            "One day I saw birds with my 'leaf notes', ok. Hope the birds will bring my knowledge to others as well.",

            -- 赋能权杖
            {
                type="img",
                name="aip_dou_empower_scepter",
            },
            "After a series of adjustments, the 'Mysterious Scepter' can get additional enhancements, but its enhancement direction is extremely unstable, I can't choose what it will strengthen, it depends on luck. But under the full moon, it is It will always be strengthened to 'moon energy' effect.",

            -- 游龙梦魇尾兽
            {
                type="anim",
                build="aip_dragon_tail",
                anim="walk_loop",
                scale=.5,
                height=80,
            },
            "Damn, the empowered scepter was destroyed by a strange shadowy creature. It swallowed the shards it fell and flew away towards the 'Sunflower Grove'.",

            -- 小麦
            {
                type="anim",
                build="aip_wheat",
                scale=.25,
                height=80,
            },
            "One day when I was picking 'hay', I found a mutated plant. It looks like 'wheat' in the real world, and it also has 'grain degree' in cooking. Interesting.",

            -- 向日葵
            {
                type="anim",
                build="aip_sunflower",
                bank="aip_sunflower",
                anim="idle_tall",
                scale=.25,
                height=200,
            },
            "Every season changes, there will always be a 'sunflower tree' nearby. If you cut it down, it will drop 1~2 sunflowers, which can also be used to make food. It also has a 'food degree'. It tastes great.",

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
            "When defeating the 'Shadow Creatures', sometimes they don't really die. If you look closely you will find their footprints. When I'm very sane, the footprints are not obvious.",

            -- 变异向日葵
            {
                type="anim",
                build="aip_sunflower",
                anim="idle_ghost",
                scale=.25,
                height=200,
            },
            "When I ran after this footprint, it escaped to the 'sunflower tree', and the tree instantly turned into a strange shape.",

            -- 游龙梦魇
            {
                type="anim",
                build="aip_dragon",
                anim="walk_loop",
                scale=.5,
                height=200,
                left=-75,
            },
            "I tried cutting down this tree, and when it fell, the guy who broke my scepter came out of the tree, and I named it 'Dragon Nightmare'. I need to stay sane and fight it when I need it, Otherwise, I will take advantage of my Aragami and cause huge damage.",

            -- 暗影碎牙
            {
                type="img",
                name="aip_dou_tooth",
            },
            "After defeating it, I got my scepter accessory back. Would anyone who don't know think it's a shadow monster's tooth?",

            -- 噩梦之灵
            {
                type="anim",
                build="aip_nightmare_package",
                scale=.35,
                height=60,
            },
            "Also dropped this 'Nightmare Spirit', I shuddered to see it. God knows why I would eat it in one bite, it feels terrible!",

            -- 闹鬼巫师帽
            {
                type="img",
                name="aip_wizard_hat",
            },
            "After defeating the heart, I got this 'Haunted Wizard Hat'. It allows me to see the shadow footprints more clearly, which is really one thing.",
        },
    },

    -- 诡影迷踪
    {
        name = "Shadoway",
        desc = {
            "While collecting moonlight glass on Tsukishima, I noticed that the perturbations of magic here were also somewhat unusual. That piqued my interest.",

            -- 联结图腾
            {
                type="anim",
                build="aip_dou_totem",
                scale=.3,
                height=120,
            },

            "I built a 'connection totem' here to use the magic here for my use.",

            -- 搬运石偶
            {
                type="img",
                name="aip_shadow_transfer",
            },
            "This 'moving stone puppet' is my favorite. It can directly mark the building and move it to a new place. It is quite convenient for moving. Of couse, I need borrow something from Merm.",

            -- 月轨测量仪
            {
                type="img",
                name="aip_track_tool",
            },
            "'Track Measurer' make a track that can cross the sea, and you can drive it with the 'Glass Mine Cart'.",
            "In addition, use 'Red Gem' upgrade to increases track, and use 'Blue Gem' upgrade to decreases track.",

            -- 玻璃矿车
            {
                type="img",
                name="aip_glass_minecar",
            },
            "Place the 'Glass Mine Cart' on the node created by the 'Track Measurer' and ride it. The arrow keys control the direction, X to exit the mine car, and V to switch the view.",

            -- 劣质的飞行图腾
            {
                type="anim",
                build="aip_fake_fly_totem",
                scale=.4,
                height=120,
            },
            "I tried to make a 'Fake Flying Totem' to use Tsukishima's magic, but I found that using it alone doesn't work, it needs at least more than one to work. Also, if not supplementing the 'Nightmare Fuel'. The mana is not enough.",

            -- 若光
            {
                type="anim",
                build="aip_mini_doujiang",
                anim="throw",
                scale=.5,
                height=80,
            },
            "I found a space-time rift near the 'Pig King', which projected the real world. To my surprise, the character 'Ruo Guang' in the original comic actually appeared in front of me and invited me to join play.",

            -- 豆豆球
            {
                type="anim",
                build="aip_score_ball",
                anim="runRight",
                scale=.4,
                height=80,
            },
            "'Ruo Guang' taught me how to make 'Doudou Ball' and play racquetball with it.",

            -- 葡萄
            {
                type="img",
                name="aip_veggie_grape",
            },
            "After the game, 'Ruo Guang' sent me some 'grapes' to quench my thirst. It also mentioned that 'grape fruit sticks' made with 'grapes' are his favorite food, and I will give it to him next time Bring some here.",

            -- 劣质的飞行图腾
            {
                type="anim",
                build="aip_fly_totem",
                scale=.4,
                height=120,
            },
            "After my many studies, I finally completed the 'Flying Totem' that purely consumes Tsukishima's magic power. I also installed one in 'Ruo Guang', so I don't need to go all the way to be a guest in the future.",

            -- 地图
            {
                type="img",
                name="aip_map",
            },
            "One day, 'Ruo Guang' told me that there was a huge white monster on the sea and drew a 'map' for me. I'm going to check it out another day.",

            -- 饼干碎裂机
            {
                type="anim",
                build="aip_cookiecutter_king",
                scale=.2,
                height=250,
                top=120,
            },
            "He's really a huge guy, if those little things are called 'cookie cutters', then this one has to be called 'cookie cutters'! He talks a lot when he sees me, but I listen to every word I don't understand. Later, I remembered the old 'Ancient Beach Pot' and took a sip because I could understand the voice of the fish. Sure enough, it works for it. This big guy is a glutton and always asks me for something to eat. But I'm actually quite free, so I'll bring it to him.",

            -- 饼干碎石
            {
                type="img",
                name="aip_shell_stone",
            },
            "But this guy is really hard to find at sea, so I asked him how to locate it. He gave me some 'cookie crumbs' and left after throwing a rock to ask for directions.",

            -- 泥蟹
            {
                type="anim",
                build="aip_mud_crab",
                anim="idle_loop",
                scale=.3,
                height=50,
            },
            "God, it actually wants to eat live 'mud crabs'. This little thing runs faster than anything else, and even the 'trap' can't catch it. But it seems that the 'eyegrass' can catch them...",

            -- 子卿
            {
                type="img",
                name="aip_suwu",
            },
            "After eating a lot, the 'Cookie Crusher' burped. A branch called 'Zi Qing' fell out, but I found its power useless. The more lonely you are, the stronger it is.",

            -- 棱镜石
            {
                type="img",
                name="aip_legion",
            },
            "The 'Prism Stone' was burped out together with 'Zi Qing'. I saw the size of this stone, and it seemed to be the same size as the 'Magic Square' slot I saw in the forest before. I Gotta try.",

            -- 魔力方阵
            {
                type="anim",
                build="aip_rubik",
                scale=.3,
                height=120,
                top=30,
            },
            "When I saw the 'Magic Square' before, I thought it was just a large 'nightmare lamp holder', but it turned out to be just the last part missing. After I installed the 'Prism Stone', something strange happened!",

            -- 诙谐之心
            {
                type="anim",
                build="aip_rubik_heart",
                scale=.3,
                height=130,
                top=-110,
            },
            "A heart suddenly appeared on the 'Magic Square', it was so oppressive.",

            -- 诙谐梦魇
            {
                type="anim",
                build="aip_rubik_ghost",
                anim="idle_loop",
                scale=.25,
                height=150,
            },
            "When I returned to my senses, I was surrounded by these shadow creatures. What's more terrifying is that every time I defeated a monster, the other monsters would become more powerful and difficult to deal with.",

            -- 启迪时克雕塑
            {
                type="anim",
                build="aip_eye_box",
                scale=.2,
                height=210,
                top=-30,
            },
            "In order not to be disturbed by the 'Enlightenment Sculpture', I sealed it with 'Connection Totem'. But just in case I still need it someday, I set up a trap. When the night of the full moon, this time The adventurous 'Beanball', 'Zi Qing' and 'Haunted Wizard Hat' can be summoned again by placing them near the 'Connection Totem'. Bye~",
        },
    },

    -- 古神低语
    {
        name = "Oldone Whisper",
        desc = {
            "In order to find inspiration a few days ago, I released the 'Enlightenment Sculpture' again. Who knew that it would run away as soon as it came out, and it was too late to use the 'mysterious scepter enhanced by the moon' to control it. Damn, don't let it I caught you!",

            -- 怪异的球茎
            {
                type="anim",
                build="aip_oldone_plant",
                anim="small",
                scale=.3,
                height=30,
                top=10,
            },
            "I don't know if it has something to do with the 'Enlightenment Sculpture', there are some strange mutations in this world. I saw some 'weird bulbs' on the ground, and if you want to pick them completely, you need to use a 'razor'. Otherwise it Broken pus is very painful to splash on.",

            -- 拟态蜘蛛
            {
                type="anim",
                build="aip_oldone_rabbit",
                scale=.25,
                height=80,
            },
            "One day I saw a creature that looked like a spider and a rabbit on the road. I wanted to see where it came from.",

            -- 寄生蜘蛛巢
            {
                type="anim",
                build="aip_oldone_spiderden",
                scale=.4,
                height=180,
                top=25,
            },
            "Following them, I found the source. It was a 'parasitic spider nest', and it looks like those 'bulbs' had parasitized into the nest while it was still fragile. But for now, they appear to be harmless.",
        
            -- 袜子蛇
            {
                type="anim",
                build="aip_oldone_thestral",
                anim="idle_loop",
                scale=.25,
                height=80,
            },
            "Beside the pig king, I saw a strange figure, and when I got close, I found it was a 'sock snake'. It's interesting to say that this kind of inexplicable creature is no longer strange to me. I'll study the broken 'bulb'. Is it true that sticky clothes can be made into cooking?",

            -- 皮质果冻
            {
                type="img",
                name="aip_food_leather_jelly",
            },
            "It's done! This 'leather jelly' is crystal clear and delicious. It's just that I occasionally see some strange things, so it shouldn't be a problem. Hahahahaha!",

            -- 袜子蛇真身
            {
                type="anim",
                build="aip_oldone_thestral_full",
                anim="idle_loop",
                scale=.25,
                height=330,
            },
            "After eating the 'Cortex Jelly', I went to the 'Pig King' for some gold as usual. But to my surprise, the original 'Sock Snake' was gone. In its place was a huge monster! It can pass through My mouth speaks! When I hear its whisper, I hear it whisper everywhere! I'm going crazy!",
        
            -- 污损的雕像
            {
                type="anim",
                build="aip_oldone_marble",
                scale=.25,
                height=200,
            },
            "I found that it really hated the regular hammering sound, so I made a marble contraption in a remote swamp. It hammered regularly. The sensitive-eared 'Sock Snake' was distracted by the sound, not at all Time is on my side, let me continue to explore this world. Hahahaha!",

            -- 捆绑的头颅
            {
                type="anim",
                build="aip_oldone_marble_head_lock",
                bank="chesspiece",
                anim="aipStruggle",
                scale=.4,
                height=120,
            },
            "Well, I don't know how the 'sock snake' moved the marble head over. It tied it up with its own fur, and now its pounding has only broken some trees.",

            -- 地毯
            {
                type="img",
                name="aip_oldone_thestral_watcher",
            },
            "I cut the fur off the stone to reset the device and tried to analyze the fur. I've found that it can temporarily associate something, but it's not stable. I tried making it a floor mat and activating it.",

            -- 笑脸
            {
                type="anim",
                build="aip_oldone_smile",
                scale=.2,
                height=300,
            },
            "Finally got to see it for what it is, I don't know what it is. It, it, it, family! leave, disappear!",

            -- 光环
            {
                type="anim",
                build="aip_aura_smiling",
                scale=.4,
                height=180,
                top=80,
            },
            "I don't know what happened, I just vaguely remember seeing something like a halo as it got closer. Now that it's gone, the halo hasn't, on the contrary something has changed. What does the pattern above imply?",

            -- 漆黑的鹿
            {
                type="anim",
                build="aip_oldone_deer",
                anim="half",
                scale=.25,
                height=160,
            },
            "Under the ground, I found a strange deer-shaped stone, covered with eye-like textures, and it seemed to be some kind of mimetic creature. But it looked half-dead. After a period of research, I found that it was actually a It was inactive because it was too cool underground. So I lit some campfires around it to try and revive it.",

            -- 菇茑
            {
                type="anim",
                build="aip_oldone_deer_eye",
                scale=.35,
                height=50,
            },
            "After warming up, a delicious 'lantern berry' grew on the edge of the stone. However, it seems that it also contains 'bulb' toxins, so you should not eat more.",

            -- 怠惰的南瓜
            {
                type="anim",
                build="aip_tricky_thrower",
                scale=.35,
                height=100,
            },
            "After using lantern berry to feed 'Jack Lantern', it mutates into a container. Interestingly, even the slightest blow can irritate it. So throw the things in your stomach to the place that is suitable for it, such as firepit~",
        },
    },

    -- 鲜花谜团
    {
        name = "Magic Puzzle",
        desc = {
            "One day I suddenly remembered a game in my world. It has a lot of small mysteries and it's quite interesting. I'm going to make some mysteries in this world, so that people who are destined to come and play. Of course, it's a mystery There is definitely a reward. As long as someone solves the mystery, I will give the decipherer the mystery factor so that they can survive better in this world~",

            -- 雪人
            {
                type="anim",
                build="aip_oldone_snowman",
                anim="snowman",
                scale=.25,
                height=200,
                loop=false,
            },
            "The most interesting thing in winter is to build a snowman. Once you prepare some big snowballs in advance, you can build them quickly.",

            -- 海荷叶
            {
                type="anim",
                build="aip_oldone_lotus_leaf",
                scale=.4,
                height=60,
                top=15,
            },
            "When I was a kid, I liked to hit the water. I would make a circle with some leaves and play with my friends to see who can hit it right.",

            -- 旺盛之树
            {
                type="anim",
                build="aip_oldone_tree",
                scale=.4,
                height=240,
            },
            "If in the woods, would anyone find a tree unusual? Hahaha, it's actually a one-time lightning rod.",

            -- 瞬息全宇宙
            {
                type="anim",
                build="aip_oldone_once",
                anim="turn",
                loop=false,
                scale=.3,
                height=80,
            },
            "Wouldn't it be fun if a rock had shiny eyes?",

            -- 幕后黑手
            {
                type="anim",
                build="aip_oldone_black",
                scale=.35,
                height=80,
            },
            "I hid a few shadow palms nearby to see if anyone could find them all.",

            -- 搁浅水母
            {
                type="anim",
                build="aip_oldone_jellyfish",
                anim="dry",
                scale=.35,
                height=50,
            },
            "This 'stranded jellyfish' isn't actually a real jellyfish, but a replica I made with a sticky coat. Feed it some kelp and it will turn into a warm jellyfish toy.",

            -- 闹鬼陶罐
            {
                type="anim",
                build="aip_oldone_pot",
                scale=.35,
                height=70,
            },
            "When these three pots are put together, any damage will be restored immediately. Let's see who can break it together in a short time?",

            -- 盐洞
            {
                type="anim",
                build="aip_oldone_salt_hole",
                scale=.35,
                height=100,
                top=10,
            },
            "People at the sea often eat salted fish, I recommend you try it too.",

            -- 化缘石像
            {
                type="anim",
                build="aip_oldone_hot",
                scale=.25,
                height=80,
            },
            "Summer is really sweaty, and it's even better to have some iced drinks.",

            -- 
            {
                type="anim",
                build="aip_watering_flower",
                anim="withered",
                scale=.35,
                height=60,
            },
            "When you see a dry flower, will you water it?",

            -- 古早花
            {
                type="anim",
                build="aip_four_flower",
                anim="open",
                scale=.35,
                height=50,
            },
            "A little game to see who can make all the flowers open~",

            -- 固定的石头
            {
                type="anim",
                build="aip_oldone_rock",
                scale=.35,
                height=50,
            },
            "Make a circle with stones and leave a gap, fill the gap.",

            -- 春日鲜花
            {
                type="anim",
                build="aip_oldone_plant_flower",
                scale=.25,
                height=100,
                top=40,
            },
            "A small mark on the ground, plant a flower that represents spring, and welcome a new day!",

            -- 落叶堆
            {
                type="anim",
                build="aip_oldone_leaves",
                scale=.35,
                height=60,
                top=10,
            },
            "Light this pile of fallen leaves and clean the yard.",

            -- 饭团食盒
            {
                type="anim",
                build="aip_oldone_rice",
                scale=.25,
                height=80,
            },
            "I leave a rick box, can you fill it? Of course, rice ball is very viscous and can be used to repair ships. I guess you must be reluctant to let it go.",
        },
    },

    -- 量力而行
    {
        name = "Quantum Mechanics",
        desc = {
            -- 粒子
            {
                type="anim",
                build="aip_particles",
                anim="idle",
                scale=.25,
                height=60,
            },

            "On rainy days, I observed sometimes strange particle disturbances near the falling thunder. They will disappear soon.",

            -- 粒子限制器
            {
                type="img",
                name="aip_particles_bottle_charged",
            },

            "I made a 'particle limiter' rig and saved it successfully for a while.",

            {
                type="img",
                name="aip_particles_entangled_blue",
            },
            {
                type="img",
                name="aip_particles_entangled_orange",
            },

            "After some exploration, I found that the stored particles can be split to form two entangled particles. When one of them is hit, the other is also affected.",

            "What's more interesting is that the perturbation doesn't seem to require much energy to trigger. For example, the smoke produced by the mushroom when it germinates will also be disturbed, and even another pair of particles may be excited! Could this perturbation also work for 'lazy pumpkins'?",

            -- 回响粒子
            {
                type="img",
                name="aip_particles_echo",
            },
            "Echo Particles will repeat trigger after a while.",

            -- 告密粒子
            {
                type="img",
                name="aip_particles_heart",
            },
            "Telltale Particles will trigger when player is nearby. Funny~",

            -- 晨曦粒子
            {
                type="img",
                name="aip_particles_morning",
            },
            "Morning particles will trigger on morning. Good morning!",

            -- 黄昏粒子
            {
                type="img",
                name="aip_particles_dusk",
            },
            "Dusk particles will trigger on dusk. It's time to go home.",

            -- 漆黑粒子
            {
                type="img",
                name="aip_particles_night",
            },
            "Night particles will trigger on night. Is campfire still on?",
        },
    },

    -- 世界掉落
    {
        name = "World Drop",
        desc = {
            "In this world, creature occasionally drop rare items. These things are not restricted by specific biological types, but drop randomly, and the probability is surprisingly low.",
        
            -- 繁荣之种
            {
                type="img",
                name="aip_prosperity_seed",
            },

            "It looks like it's made of moonlight glass, but it's really a seed. The planted 'Prosperity Tree' has the ability to reproduce.",

            -- 繁荣之树
            {
                type="anim",
                build="aip_prosperity_tree",
                scale=.3,
                height=260,
            },

            "After giving it the fruit and vegetables it grows, it will remember its entity. And grow some every day, drop when the growth is complete and grow again. The 'Pickaxe' will turn back into 'Seed of Prosperity' after hitting it.",

            -- 草肝
            {
                type="img",
                name="aip_liver_grass",
            },
            -- 木肝
            {
                type="img",
                name="aip_liver_log",
            },
            -- 石肝
            {
                type="img",
                name="aip_liver_stone",
            },
            "A liver model made of useless materials. In my world, it is said that letting players do meaningless repetitive things is the 'liver'. Doing the relevant things by category will lower the percentage, but nothing will happen to 0%.",

            -- 金肝
            {
                type="img",
                name="aip_liver_gold",
            },
            "The same useless liver model, if gold is used to make items, the percentage will be reduced. That's all.",

            -- 宝石肝
            {
                type="img",
                name="aip_liver_gem",
            },
            "Yet another useless liver model that reduces percentage when crafting gems.",

            -- 虹光肝
            {
                type="img",
                name="aip_liver_opalprecious",
            },
            "The only liver model of any value, it restores a lot of 3D when eaten. And randomly drop a liver model.",
        
            -- 奥卡姆剃刀
            {
                type="img",
                name="aip_ockham_razor",
            },
            "Ockham's Razor like an ordinary razor, and at the same time has a certain combat effectiveness, but its damage will decrease with the number of times it is used. Fortunately, the durability can be restored with charged particles.",

            -- 阿兹特克金币
            {
                type="img",
                name="aip_aztecs_coin",
            },
            "Aztecs Coin is cursed that grants a gold nugget at the cost of life each time when use.",

            -- 回旋铁球
            {
                type="img",
                name="aip_steel_ball",
            },
            "A steel ball with whirling power. After being thrown out, it will help you transfer damage to trees, stones, etc. with CD.",
        
            -- 永恒之井
            {
                type="anim",
                build="aip_forever",
                scale=.35,
                height=170,
                top=20,
            },
            "A well full of vitality that grows a normal or demonic flower nearby every day. If you give petals, you can directly grow the corresponding flower but may fail to turn into a butterfly.",
        
            -- 光荣之手
            {
                type="img",
                name="aip_glory_hand",
            },
            "'Hand of Glory' will summon a light source for everyone, so that friends without torches can see clearly ahead in the dark. It can be fueled by 'Nightmare Fuel'.",
            
            -- 石鬼面
            {
                type="img",
                name="aip_stone_mask",
            },
            "This broken mask still has some magical powers, and when used it fears nearby creatures if possible.",

            -- 缘梦
            {
                type="img",
                name="aip_dream_stone",
            },
            "The stone is full of magic which makes every nearby fall asleep.",

            -- 傅达
            {
                type="anim",
                build="aip_oldone_thrower",
                scale=.35,
                height=140,
                top=20,
            },
            "A knowledgeable owl statue, playing games with it can get some rewards.",

            -- 炉石
            {
                type="img",
                name="aip_hearthstone",
            },
            "This stone can take you to the Florid Postern, but it's not stable.",
        },
    },

    -- 动物之友
    {
        name = "Cute Animals",
        desc = {
            "I found that in addition to the special pets that can be found in the rock lair, some small animals in the wild can also be tamed. All it takes is some special food.",

            -- 小动物甜品
            {
                type="img",
                name="aip_pet_catcher",
            },
            "'Animal Dessert' is very sweet and greasy, there is a certain probability of taming it when thrown to it. However, as the quality of small animals improves, the success rate of taming gradually decreases. That's when you need to prepare more desserts. Of course, the small animals I can manage are actually limited.",

            -- 明目药膏
            {
                type="img",
                name="aip_fig_salve",
            },
            "'Fig Salve' can improve the ability of observation, so that I can see the quality of small animals clearly for a period of time. According to the color of the aperture under the feet are:",

            "- Normal",
            {
                type="txt",
                text="- Nice",
                color = PET_QUALITY_COLORS[2],
            },
            {
                type="txt",
                text="- Great",
                color = PET_QUALITY_COLORS[3],
            },
            {
                type="txt",
                text="- Outstanding",
                color = PET_QUALITY_COLORS[4],
            },
            {
                type="txt",
                text="- Perfect",
                color = PET_QUALITY_COLORS[5],
            },

            "Small animals have their own skills. As the quality increases, the number of skills and the maximum level will increase. But correspondingly, high-quality small animals are hard to come by.",

            -- 小动物埙
            {
                type="img",
                name="aip_pet_trigger",
            },
            "Small animals can here the post, which can be used to release or put away small animals.",

            -- 小动物纸盒
            {
                type="img",
                name="aip_pet_box",
            },
            "Small animal like this box. You can put it in.",

            -- 榴莲糖
            {
                type="img",
                name="durian_sugar",
            },
            "Although I can feed small animals to increase ability, but do not feed 'durian sugar'. They will leave you because they are very resistant to this food!",
            "Note that one food a day is enough. Too many foods will get less benefits.",

            -- 小动物软糖
            {
                type="img",
                name="aip_pet_fudge",
            },
            "Small animal like eat this fudge which helps updgrade skill quality. But can not eat too much.",
        },
    },
}