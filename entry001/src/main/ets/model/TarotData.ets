// 治愈之书 - 核心数据模型

import { AppStorage } from '@kit.ArkUI';

export interface TarotCard {
  id: number;
  name: string;
  name_en: string;
  image: string; // 存储完整的 https 链接 (默认牌组)
  meaning: string;
  desc: string;
}

// 🎨 牌组主题接口
export interface DeckTheme {
  id: string;
  name: string;
  desc: string;
  folder: string; // OBS 文件夹名，例如 "default/"
  price: number; // 价格 (心力值)
  preview: string; // 预览图文件名
  isLocked: boolean; // 初始状态 (实际状态需结合用户购买记录)
}

// 🛠️ 配置：是否使用本地图片
// true: 使用本地 rawfile 中的图片 (需将图片放入 resources/rawfile 目录)
// false: 使用华为云 OBS 图片
const USE_LOCAL_IMAGES = false;

// 🔴 OBS 根路径
export const OBS_ROOT_URL = 'https://taluopai.obs.cn-southwest-2.myhuaweicloud.com/tarot_cards/';

// 📦 牌组列表配置
export const DECK_LIST: DeckTheme[] = [
  {
    id: 'default',
    name: '治愈绘本',
    desc: '温暖治愈的绘本风格，适合日常情感疗愈。',
    folder: 'impasto%20style/', // 默认文件夹 (请确保OBS中有此文件夹)
    price: 0,
    preview: 'card_0.png',
    isLocked: false
  },
  {
    id: 'classic',
    name: '经典韦特',
    desc: '神秘的经典韦特塔罗，符号象征丰富。',
    folder: 'classic/', // 示例文件夹
    price: 60,
    preview: 'card_0.png',
    isLocked: true
  },
  {
    id: 'watercolor',
    name: '水彩梦境',
    desc: '轻盈通透的水彩质感，如梦似幻。',
    folder: 'watercolor/', // 示例文件夹
    price: 88,
    preview: 'card_0.png',
    isLocked: true
  }
];

// 辅助函数：构建完整的图片 URL (初始化时使用默认牌组)
function getImageUrl(filename: string): string {
  if (filename.startsWith('http')) return filename;
  if (USE_LOCAL_IMAGES) return filename;
  // 默认使用第一个牌组
  return `${OBS_ROOT_URL}${DECK_LIST[0].folder}${filename}`;
}

// 🔄 核心：动态解析当前牌组图片
export function resolveDeckImage(originalUrl: string): string {
  if (!originalUrl) return originalUrl;
  if (USE_LOCAL_IMAGES) return originalUrl;
  
  // 如果是网络图片，提取文件名并重新拼接当前牌组路径
  if (originalUrl.startsWith('http')) {
    const filename = originalUrl.split('/').pop();
    if (!filename) return originalUrl;
    
    // 从 AppStorage 获取当前选中的牌组文件夹 (默认为第一个)
    const currentFolder = AppStorage.Get<string>('CurrentDeckFolder') || DECK_LIST[0].folder;
    return `${OBS_ROOT_URL}${currentFolder}${filename}`;
  }
  return originalUrl;
}

// 22张大阿卡纳 - 治愈绘本风数据
const MAJOR_ARCANA: TarotCard[] = [
  {
    id: 0,
    name: "愚人",
    name_en: "The Fool",
    image: getImageUrl("card_0.png"),
    meaning: "新的开始 · 纯真 · 冒险",
    desc: "像孩子一样迈出第一步吧。不要担心会不会摔倒，云朵会接住你的。今天的运气藏在那些看似傻傻的决定里。"
  },
  {
    id: 1,
    name: "魔术师",
    name_en: "The Magician",
    image: getImageUrl("card_1.png"),
    meaning: "创造 · 可能性 · 魔法",
    desc: "你手里握着所有的魔法道具。无论是生活还是工作，只要你相信，你就能把枯燥的日子变成一场精彩的魔术秀。"
  },
  {
    id: 2,
    name: "女祭司",
    name_en: "The High Priestess",
    image: getImageUrl("card_2.png"),
    meaning: "直觉 · 宁静 · 倾听",
    desc: "嘘，安静下来。答案不在外面的喧嚣里，而在你心里的那个小花园里。相信你的直觉，它比什么都准。"
  },
  {
    id: 3,
    name: "皇后",
    name_en: "The Empress",
    image: getImageUrl("card_3.png"),
    meaning: "丰收 · 关爱 · 享受",
    desc: "今天是被爱包围的一天。去吃顿好吃的，去买束花，或者只是躺在草地上晒晒太阳。你值得这世间所有的温柔。"
  },
  {
    id: 4,
    name: "皇帝",
    name_en: "The Emperor",
    image: getImageUrl("card_4.png"),
    meaning: "守护 · 秩序 · 坚定",
    desc: "建立属于你自己的小王国。无论是整理房间还是规划未来，现在的每一分坚持，都是为了以后能更安心地做自己。"
  },
  {
    id: 5,
    name: "教皇",
    name_en: "The Hierophant",
    image: getImageUrl("card_5.png"),
    meaning: "指引 · 学习 · 传统",
    desc: "如果感到迷茫，不妨听听长辈或书本的建议。有时候，古老的智慧就像一杯热茶，能温暖你不安的心。"
  },
  {
    id: 6,
    name: "恋人",
    name_en: "The Lovers",
    image: getImageUrl("card_6.png"),
    meaning: "选择 · 和谐 · 吸引",
    desc: "跟随你的心跳声做决定。无论是对人还是对事，那份让你嘴角上扬的悸动，就是最好的指南针。"
  },
  {
    id: 7,
    name: "战车",
    name_en: "The Chariot",
    image: getImageUrl("card_7.png"),
    meaning: "勇气 · 前进 · 胜利",
    desc: "握紧你的方向盘，出发吧！路途可能有点颠簸，但你驾驶的是通往梦想的南瓜马车，Nothing can block you."
  },
  {
    id: 8,
    name: "力量",
    name_en: "Strength",
    image: getImageUrl("card_8.png"),
    meaning: "温柔 · 耐心 · 内心强大",
    desc: "真正的力量不是大声咆哮，而是温柔地坚持。你比想象中更坚韧，就像能驯服狮子的少女，用爱化解一切难题。"
  },
  {
    id: 9,
    name: "隐士",
    name_en: "The Hermit",
    image: getImageUrl("card_9.png"),
    meaning: "独处 · 探索 · 光芒",
    desc: "给自己一段独处的时光吧。像提灯的小蜗牛一样，虽然走得慢，但每一步都踩在自己节奏上，心里亮堂堂的。"
  },
  {
    id: 10,
    name: "命运之轮",
    name_en: "Wheel of Fortune",
    image: getImageUrl("card_10.png"),
    meaning: "转折 · 幸运 · 惊喜",
    desc: "生活的摩天轮转起来了！低谷之后一定是高处。准备好迎接惊喜吧，好运气正在转角处等你。"
  },
  {
    id: 11,
    name: "正义",
    name_en: "Justice",
    image: getImageUrl("card_11.png"),
    meaning: "平衡 · 诚实 · 清晰",
    desc: "心里的天平会告诉你什么是对的。做一个正直而真实的人，今晚你会拥有一个像婴儿般安稳的睡眠。"
  },
  {
    id: 12,
    name: "倒吊人",
    name_en: "The Hanged Man",
    image: getImageUrl("card_12.png"),
    meaning: "换个角度 · 等待 · 放松",
    desc: "如果路走不通，不如换个姿势看世界？倒过来看，天空变成了大海。暂停一下没关系，那是为了积蓄跳跃的力量。"
  },
  {
    id: 13,
    name: "死神",
    name_en: "Death",
    image: getImageUrl("card_13.png"),
    meaning: "重生 · 告别 · 新芽",
    desc: "不要害怕结束。落叶是为了给新芽腾出位置。和过去那些让你不开心的事说再见吧，崭新的明天正在发芽。"
  },
  {
    id: 14,
    name: "节制",
    name_en: "Temperance",
    image: getImageUrl("card_14.png"),
    meaning: "调和 · 治愈 · 恰到好处",
    desc: "不急不躁，慢慢来。把生活里的酸甜苦辣调配成一杯好喝的果汁。保持平衡，你就是最好的生活艺术家。"
  },
  {
    id: 15,
    name: "恶魔",
    name_en: "The Devil",
    image: getImageUrl("card_15.png"),
    meaning: "束缚 · 诱惑 · 觉察",
    desc: "是不是太贪吃甜食了？或者沉迷手机太久了？没关系，意识到这一点，轻轻解开那些糖果做的锁链就好。"
  },
  {
    id: 16,
    name: "高塔",
    name_en: "The Tower",
    image: getImageUrl("card_16.png"),
    meaning: "突变 · 释放 · 觉醒",
    desc: "有时候，积木塔倒了是为了让你搭个城堡。别怕突如其来的变化，那也许是命运想送你一份意想不到的礼物。"
  },
  {
    id: 17,
    name: "星星",
    name_en: "The Star",
    image: getImageUrl("card_17.png"),
    meaning: "希望 · 灵感 · 闪耀",
    desc: "抬头看看夜空，你是最亮的那颗星。无论现在多黑，希望永远都在。许个愿吧，宇宙正在听呢。"
  },
  {
    id: 18,
    name: "月亮",
    name_en: "The Moon",
    image: getImageUrl("card_18.png"),
    meaning: "梦境 · 潜意识 · 朦胧",
    desc: "今晚的梦也许会给你答案。不必看清前路的每一步，借助月光，相信直觉，慢慢走，不会迷路的。"
  },
  {
    id: 19,
    name: "太阳",
    name_en: "The Sun",
    image: getImageUrl("card_19.png"),
    meaning: "快乐 · 成功 · 活力",
    desc: "快乐得像个孩子一样！没什么大不了的，阳光正好，微风不燥，今天是充满电量、闪闪发光的一天。"
  },
  {
    id: 20,
    name: "审判",
    name_en: "Judgement",
    image: getImageUrl("card_20.png"),
    meaning: "召唤 · 觉醒 · 清晰",
    desc: "听到了吗？那是内心深处的号角声。是时候展开翅膀了，告别旧的自己，去拥抱那个更棒的你。"
  },
  {
    id: 21,
    name: "世界",
    name_en: "The World",
    image: getImageUrl("card_21.png"),
    meaning: "圆满 · 完成 · 旅程",
    desc: "你已经做得够好了。给自己一个大大的拥抱吧。所有的努力都开出了花，尽情享受这完美的时刻。"
  }
];

// 权杖组 (Wands) - 火元素：行动、热情、灵感
const WANDS_DECK: TarotCard[] = [
  { id: 22, name: "权杖王牌", name_en: "Ace of Wands", image: getImageUrl("wands_ace.png"), meaning: "灵感 · 新行动 · 激情", desc: "一个新的点子点燃了你的热情！就像刚划着的火柴，充满了无限可能。抓住这个瞬间，大胆去做吧。" },
  { id: 23, name: "权杖二", name_en: "Two of Wands", image: getImageUrl("wands_2.png"), meaning: "规划 · 展望 · 决定", desc: "你站在城堡上眺望远方，世界在你手中。是留在这里，还是去探索更广阔的天地？听从内心的召唤。" },
  { id: 24, name: "权杖三", name_en: "Three of Wands", image: getImageUrl("wands_3.png"), meaning: "远见 · 合作 · 探索", desc: "你的船只已经扬帆起航。付出开始有了回报，现在的你需要耐心等待，同时在这个过程中寻找志同道合的伙伴。" },
  { id: 25, name: "权杖四", name_en: "Four of Wands", image: getImageUrl("wands_4.png"), meaning: "庆祝 · 归属 · 稳定", desc: "欢迎回家！这是一个值得庆祝的时刻。无论是完成了一个小目标，还是单纯的家庭聚会，享受这份安稳的快乐。" },
  { id: 26, name: "权杖五", name_en: "Five of Wands", image: getImageUrl("wands_5.png"), meaning: "竞争 · 冲突 · 磨练", desc: "周围可能有点吵闹，大家的意见都不一样。但这只是良性的切磋，在碰撞中，你会更清楚自己想要什么。" },
  { id: 27, name: "权杖六", name_en: "Six of Wands", image: getImageUrl("wands_6.png"), meaning: "胜利 · 认可 · 荣耀", desc: "你骑着马凯旋归来，掌声属于你！你的努力被大家看到了，享受这一刻的荣耀吧，这是你应得的。" },
  { id: 28, name: "权杖七", name_en: "Seven of Wands", image: getImageUrl("wands_7.png"), meaning: "坚持 · 勇气 · 防守", desc: "也许你正面临挑战，感觉大家都在反对你。但请坚持住立场，你比你想象的要强大，守住你的阵地！" },
  { id: 29, name: "权杖八", name_en: "Eight of Wands", image: getImageUrl("wands_8.png"), meaning: "迅速 · 消息 · 变化", desc: "事情正在飞速发展！好消息像流星一样向你飞来。保持专注，跟上这个节奏，一切都会很顺利。" },
  { id: 30, name: "权杖九", name_en: "Nine of Wands", image: getImageUrl("wands_9.png"), meaning: "韧性 · 警惕 · 坚持", desc: "虽然有点累，甚至受了点伤，但你依然站立着。黎明前的黑暗最难熬，但你离终点只差最后一步了，别放弃。" },
  { id: 31, name: "权杖十", name_en: "Ten of Wands", image: getImageUrl("wands_10.png"), meaning: "重担 · 责任 · 压力", desc: "你是不是承担了太多？虽然你很能干，但也不要累坏了自己。试着放下一些不属于你的包袱，你会走得更轻快。" },
  { id: 32, name: "权杖侍从", name_en: "Page of Wands", image: getImageUrl("wands_page.png"), meaning: "探索 · 消息 · 热情", desc: "像个好奇的孩子一样去探索世界吧！一个新的兴趣或消息让你跃跃欲试，保持这份赤子之心。" },
  { id: 33, name: "权杖骑士", name_en: "Knight of Wands", image: getImageUrl("wands_knight.png"), meaning: "行动 · 冲动 · 冒险", desc: "你充满了能量，简直马上出发！这种热情很棒，但记得看清路况再冲刺，别让冲动带偏了方向。" },
  { id: 34, name: "权杖王后", name_en: "Queen of Wands", image: getImageUrl("wands_queen.png"), meaning: "魅力 · 自信 · 独立", desc: "你是人群中发光的那一个。自信、热情、有感染力。相信自己的魅力，像向日葵一样永远面向阳光。" },
  { id: 35, name: "权杖国王", name_en: "King of Wands", image: getImageUrl("wands_king.png"), meaning: "领导 · 远见 · 魅力", desc: "你拥有掌控全局的能力。用你的热情去感染他人，成为大家的领路人。你的愿景不仅能激励自己，也能照亮别人。" }
];

// 星币组 (Pentacles) - 土元素：物质、工作、现实
const PENTACLES_DECK: TarotCard[] = [
  { id: 64, name: "星币王牌", name_en: "Ace of Pentacles", image: getImageUrl("pentacles_ace.png"), meaning: "财富 · 机会 · 扎根", desc: "一颗金灿灿的种子落在了你手里。这是一个关于物质或工作的新机会。踏实地种下它，只要你用心浇灌，它会长成参天大树。" },
  { id: 65, name: "星币二", name_en: "Two of Pentacles", image: getImageUrl("pentacles_2.png"), meaning: "平衡 · 适应 · 灵活", desc: "生活就像骑独轮车，你需要不断调整重心。虽然有点手忙脚乱，但你其实玩得挺转。保持灵活，你能hold住这一切。" },
  { id: 66, name: "星币三", name_en: "Three of Pentacles", image: getImageUrl("pentacles_3.png"), meaning: "团队 · 技能 · 合作", desc: "三个臭皮匠，顶个诸葛亮。和大家一起合作，每个人的特长都能发挥出来。这不仅是完成任务，更是打磨手艺的过程。" },
  { id: 67, name: "星币四", name_en: "Four of Pentacles", image: getImageUrl("pentacles_4.png"), meaning: "守财 · 安全 · 固执", desc: "把钱抱得太紧，手就没法去拿别的东西了。安全感很重要，但也不要为了安全而拒绝变化。试着松开一点手，你会拥有更多。" },
  { id: 68, name: "星币五", name_en: "Five of Pentacles", image: getImageUrl("pentacles_5.png"), meaning: "贫困 · 困难 · 互助", desc: "外面风雪交加，但教堂的窗户透着光。也许现在有点艰难，觉得孤立无援。但别只盯着脚下的雪，抬头看看，帮助其实就在身边。" },
  { id: 69, name: "星币六", name_en: "Six of Pentacles", image: getImageUrl("pentacles_6.png"), meaning: "慷慨 · 给予 · 接受", desc: "给予和接受是爱的循环。如果你有余力，不妨帮帮别人；如果你需要帮助，也请大方接受。善意流动起来，世界会更美好。" },
  { id: 70, name: "星币七", name_en: "Seven of Pentacles", image: getImageUrl("pentacles_7.png"), meaning: "评估 · 耐心 · 收获", desc: "你已经辛勤耕耘了很久，现在是停下来看看成果的时候了。也许还没到丰收的季节，但果实已经挂在枝头。耐心点，时间会给你答案。" },
  { id: 71, name: "星币八", name_en: "Eight of Pentacles", image: getImageUrl("pentacles_8.png"), meaning: "专注 · 匠人 · 细节", desc: "专注于手头的工作，像个匠人一样精雕细琢。不需要在意别人的眼光，你的每一锤、每一凿都在积累你的实力。享受专注的快乐。" },
  { id: 72, name: "星币九", name_en: "Nine of Pentacles", image: getImageUrl("pentacles_9.png"), meaning: "富足 · 独立 · 优雅", desc: "你站在自己花园里，享受着丰盛的果实。这都是你自己努力得来的。保持优雅和自信，你值得拥有这种富足的生活。" },
  { id: 73, name: "星币十", name_en: "Ten of Pentacles", image: getImageUrl("pentacles_10.png"), meaning: "传承 · 财富 · 家庭", desc: "这是一个繁荣的景象，物质和精神都很富足。这不仅是你一个人的成功，更是家族的荣耀。感恩前人的积累，也为后人种下希望。" },
  { id: 74, name: "星币侍从", name_en: "Page of Pentacles", image: getImageUrl("pentacles_page.png"), meaning: "学习 · 务实 · 专注", desc: "像个学生一样认真学习新技能吧。脚踏实地，一步一个脚印。虽然慢一点，但每一步都走得很稳，这是通往成功的必经之路。" },
  { id: 75, name: "星币骑士", name_en: "Knight of Pentacles", image: getImageUrl("pentacles_knight.png"), meaning: "勤奋 · 负责 · 可靠", desc: "你可能不是最快的，但你绝对是最靠谱的。既然承诺了，就一定会做到。这份坚持和责任感，是你最宝贵的品质。" },
  { id: 76, name: "星币王后", name_en: "Queen of Pentacles", image: getImageUrl("pentacles_queen.png"), meaning: "照顾 · 繁荣 · 务实", desc: "你是一个会过日子的人，能把生活打理得井井有条。既能赚钱养家，又能貌美如花。享受物质带来的舒适，也用爱去滋养家人。" },
  { id: 77, name: "星币国王", name_en: "King of Pentacles", image: getImageUrl("pentacles_king.png"), meaning: "成功 · 稳重 · 富有", desc: "你已经建立了自己的商业帝国。稳重、踏实、有眼光。用你的资源去创造更大的价值，享受这稳稳的幸福。" }
];


// 圣杯组 (Cups) - 水元素：情感、关系、直觉
const CUPS_DECK: TarotCard[] = [
  { id: 36, name: "圣杯王牌", name_en: "Ace of Cups", image: getImageUrl("cups_ace.png"), meaning: "爱 · 情感 · 新开始", desc: "爱意正在溢出！这可能是一段新感情，或者内心深处的自我接纳。敞开心扉，让这股温柔的能量流进来。" },
  { id: 37, name: "圣杯二", name_en: "Two of Cups", image: getImageUrl("cups_2.png"), meaning: "连接 · 伙伴 · 吸引", desc: "这是心与心碰撞的时刻。无论是恋人还是朋友，一个平等的、互相尊重的关系正在建立，享受这份默契。" },
  { id: 38, name: "圣杯三", name_en: "Three of Cups", image: getImageUrl("cups_3.png"), meaning: "欢庆 · 友谊 · 团体", desc: "叫上朋友们一起庆祝吧！分享快乐会让快乐加倍。这是一个轻松愉快的时刻，尽情享受友谊的滋润。" },
  { id: 39, name: "圣杯四", name_en: "Four of Cups", image: getImageUrl("cups_4.png"), meaning: "观望 · 厌倦 · 思考", desc: "也许你对现状有点提不起劲，甚至忽略了眼前递给你的机会。没关系，给自己一点发呆的时间，但也别忘了抬头看看。" },
  { id: 40, name: "圣杯五", name_en: "Five of Cups", image: getImageUrl("cups_5.png"), meaning: "失落 · 悲伤 · 遗憾", desc: "打翻了牛奶也没办法挽回。允许自己难过一会儿，但别忘了身后还有两个杯子是立着的。珍惜留下的，依然很美好。" },
  { id: 41, name: "圣杯六", name_en: "Six of Cups", image: getImageUrl("cups_6.png"), meaning: "回忆 · 纯真 · 怀旧", desc: "一段温暖的往事涌上心头。或者是遇到了像童年玩伴一样真诚的人。简单的快乐最动人，像孩子一样去爱吧。" },
  { id: 42, name: "圣杯七", name_en: "Seven of Cups", image: getImageUrl("cups_7.png"), meaning: "幻想 · 选择 · 迷茫", desc: "好多选择摆在面前，每个看起来都很诱人。但小心哦，有些只是美丽的泡沫。擦亮眼睛，问问自己到底需要哪一个。" },
  { id: 43, name: "圣杯八", name_en: "Eight of Cups", image: getImageUrl("cups_8.png"), meaning: "寻找 · 离开 · 追寻", desc: "虽然这里什么都有，但你心里知道这不够。勇敢地转身吧，去寻找那个能真正填满你内心空缺的东西，哪怕路途遥远。" },
  { id: 44, name: "圣杯九", name_en: "Nine of Cups", image: getImageUrl("cups_9.png"), meaning: "满足 · 愿望 · 享受", desc: "愿望成真了！现在的你就像个满足的猫咪，享受着生活的馈赠。这是属于你的幸福时刻，不需要向任何人解释。" },
  { id: 45, name: "圣杯十", name_en: "Ten of Cups", image: getImageUrl("cups_10.png"), meaning: "幸福 · 家庭 · 圆满", desc: "彩虹挂在天边，家人朋友环绕在侧。这就是完美的幸福画面。珍惜这份稳稳的爱，它就是你最坚强的后盾。" },
  { id: 46, name: "圣杯侍从", name_en: "Page of Cups", image: getImageUrl("cups_page.png"), meaning: "好奇 · 创意 · 消息", desc: "也许会收到一封情书，或者突然有了一个浪漫的点子。保持敏感和好奇，你的直觉现在准得惊人。" },
  { id: 47, name: "圣杯骑士", name_en: "Knight of Cups", image: getImageUrl("cups_knight.png"), meaning: "浪漫 · 邀请 · 追求", desc: "白马王子（或公主）带着爱意走来了。这是一个追求梦想和爱情的好时机，听从内心的声音，温柔地前进。" },
  { id: 48, name: "圣杯王后", name_en: "Queen of Cups", image: getImageUrl("cups_queen.png"), meaning: "慈悲 · 倾听 · 直觉", desc: "你像大海一样包容。倾听内心的声音，也去关怀身边的人。你的温柔具有治愈一切的力量，相信你的直觉。" },
  { id: 49, name: "圣杯国王", name_en: "King of Cups", image: getImageUrl("cups_king.png"), meaning: "宽容 · 平衡 · 掌控", desc: "即使内心波涛汹涌，表面依然平静如水。你学会了如何与情绪共处，用成熟和宽容去处理一切，你是情感的主人。" }
];

// 宝剑组 (Swords) - 风元素：理智、思想、冲突
const SWORDS_DECK: TarotCard[] = [
  { id: 50, name: "宝剑王牌", name_en: "Ace of Swords", image: getImageUrl("swords_ace.png"), meaning: "清晰 · 真相 · 决断", desc: "思维突然变得清晰无比！挥剑斩断乱麻，这是做出理智决定的好时机。真理掌握在你手中，勇敢地面对它。" },
  { id: 51, name: "宝剑二", name_en: "Two of Swords", image: getImageUrl("swords_2.png"), meaning: "僵局 · 逃避 · 平衡", desc: "蒙上眼睛并不代表问题不存在。你在逃避做一个决定，因为怕打破平衡。但只有摘下眼罩，才能看清出路。" },
  { id: 52, name: "宝剑三", name_en: "Three of Swords", image: getImageUrl("swords_3.png"), meaning: "心碎 · 悲伤 · 释放", desc: "心痛是真实的，不要假装没事。下雨天也没关系，痛快地哭一场吧。眼泪会冲刷掉伤口，痊愈从承认痛苦开始。" },
  { id: 53, name: "宝剑四", name_en: "Four of Swords", image: getImageUrl("swords_4.png"), meaning: "休息 · 恢复 · 沉思", desc: "你太累了，脑子需要关机重启。找个安静的角落躺一会儿，什么都别想。现在的停顿，是为了接下来能走得更远。" },
  { id: 54, name: "宝剑五", name_en: "Five of Swords", image: getImageUrl("swords_5.png"), meaning: "争执 · 胜利 · 代价", desc: "虽然赢了争吵，但可能输了感情。这种胜利真的值得吗？有时候，退一步海阔天空，放下胜负心，你会更轻松。" },
  { id: 55, name: "宝剑六", name_en: "Six of Swords", image: getImageUrl("swords_6.png"), meaning: "过渡 · 疗愈 · 前行", desc: "最艰难的时刻已经过去了。虽然心情还有点沉重，但船正在驶向平静的水域。带上你的经验，继续前行吧。" },
  { id: 56, name: "宝剑七", name_en: "Seven of Swords", image: getImageUrl("swords_7.png"), meaning: "策略 · 隐秘 · 孤胆", desc: "有时候不能硬碰硬，需要一点小聪明。也许你想独自解决问题，但要小心，别聪明反被聪明误，诚实面对自己。" },
  { id: 57, name: "宝剑八", name_en: "Eight of Swords", image: getImageUrl("swords_8.png"), meaning: "束缚 · 限制 · 恐慌", desc: "你觉得自己被困住了，但看看周围，那些剑并没有把你围死。限制往往来自内部的恐惧，睁开眼，你其实可以走出来的。" },
  { id: 58, name: "宝剑九", name_en: "Nine of Swords", image: getImageUrl("swords_9.png"), meaning: "焦虑 · 噩梦 · 压力", desc: "深夜的焦虑最折磨人。那些脑海里的怪物其实没那么可怕。天亮之后，你会发现一切都只是影子。深呼吸，试着睡个好觉。" },
  { id: 59, name: "宝剑十", name_en: "Ten of Swords", image: getImageUrl("swords_10.png"), meaning: "结束 · 痛苦 · 黎明", desc: "已经不能更坏了，这反而是一种解脱。最黑暗的时刻意味着黎明即将来临。所有的痛苦都结束了，准备迎接新生吧。" },
  { id: 60, name: "宝剑侍从", name_en: "Page of Swords", image: getImageUrl("swords_page.png"), meaning: "机智 · 观察 · 谨慎", desc: "你现在思维敏捷，像个侦探一样观察周围。这种警觉很好，但也别太紧绷了。保持好奇心，小心求证。" },
  { id: 61, name: "宝剑骑士", name_en: "Knight of Swords", image: getImageUrl("swords_knight.png"), meaning: "急躁 · 直接 · 锋利", desc: "你说话直来直去，行动如风。这很有效率，但也要注意别误伤了别人。慢一点点，把你的锐气用在解决问题上。" },
  { id: 62, name: "宝剑王后", name_en: "Queen of Swords", image: getImageUrl("swords_queen.png"), meaning: "独立 · 敏锐 · 坦率", desc: "你不需要依赖任何人，你的头脑就是最强的武器。保持清醒和理智，切断那些不再适合你的人际关系，做自己的女王。" },
  { id: 63, name: "宝剑国王", name_en: "King of Swords", image: getImageUrl("swords_king.png"), meaning: "权威 · 理智 · 公正", desc: "用理智去判断，而不是用感情。你现在需要像法官一样公正地看待问题。清晰的逻辑会带你找到最正确的答案。" }
];

export const TAROT_DECK: TarotCard[] = [...MAJOR_ARCANA, ...WANDS_DECK, ...CUPS_DECK, ...SWORDS_DECK, ...PENTACLES_DECK];