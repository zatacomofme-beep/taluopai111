// 治愈之书 - 核心数据模型

export interface TarotCard {
  id: number;
  name: string;
  name_en: string;
  image: string;
  meaning: string;
  desc: string;
}

// 22张大阿卡纳 - 治愈绘本风数据
export const TAROT_DECK: TarotCard[] = [
  {
    id: 0,
    name: "愚人",
    name_en: "The Fool",
    image: "card_0.png", // 确保rawfile里是png
    meaning: "新的开始 · 纯真 · 冒险",
    desc: "像孩子一样迈出第一步吧。不要担心会不会摔倒，云朵会接住你的。今天的运气藏在那些看似傻傻的决定里。"
  },
  {
    id: 1,
    name: "魔术师",
    name_en: "The Magician",
    image: "card_1.png",
    meaning: "创造 · 可能性 · 魔法",
    desc: "你手里握着所有的魔法道具。无论是生活还是工作，只要你相信，你就能把枯燥的日子变成一场精彩的魔术秀。"
  },
  {
    id: 2,
    name: "女祭司",
    name_en: "The High Priestess",
    image: "card_2.png",
    meaning: "直觉 · 宁静 · 倾听",
    desc: "嘘，安静下来。答案不在外面的喧嚣里，而在你心里的那个小花园里。相信你的直觉，它比什么都准。"
  },
  {
    id: 3,
    name: "皇后",
    name_en: "The Empress",
    image: "card_3.png",
    meaning: "丰收 · 关爱 · 享受",
    desc: "今天是被爱包围的一天。去吃顿好吃的，去买束花，或者只是躺在草地上晒晒太阳。你值得这世间所有的温柔。"
  },
  {
    id: 4,
    name: "皇帝",
    name_en: "The Emperor",
    image: "card_4.png",
    meaning: "守护 · 秩序 · 坚定",
    desc: "建立属于你自己的小王国。无论是整理房间还是规划未来，现在的每一分坚持，都是为了以后能更安心地做自己。"
  },
  {
    id: 5,
    name: "教皇",
    name_en: "The Hierophant",
    image: "card_5.png",
    meaning: "指引 · 学习 · 传统",
    desc: "如果感到迷茫，不妨听听长辈或书本的建议。有时候，古老的智慧就像一杯热茶，能温暖你不安的心。"
  },
  {
    id: 6,
    name: "恋人",
    name_en: "The Lovers",
    image: "card_6.png",
    meaning: "选择 · 和谐 · 吸引",
    desc: "跟随你的心跳声做决定。无论是对人还是对事，那份让你嘴角上扬的悸动，就是最好的指南针。"
  },
  {
    id: 7,
    name: "战车",
    name_en: "The Chariot",
    image: "card_7.png",
    meaning: "勇气 · 前进 · 胜利",
    desc: "握紧你的方向盘，出发吧！路途可能有点颠簸，但你驾驶的是通往梦想的南瓜马车，没有什么能挡住你。"
  },
  {
    id: 8,
    name: "力量",
    name_en: "Strength",
    image: "card_8.png",
    meaning: "温柔 · 耐心 · 内心强大",
    desc: "真正的力量不是大声咆哮，而是温柔地坚持。你比想象中更坚韧，就像能驯服狮子的少女，用爱化解一切难题。"
  },
  {
    id: 9,
    name: "隐士",
    name_en: "The Hermit",
    image: "card_9.png",
    meaning: "独处 · 探索 · 光芒",
    desc: "给自己一段独处的时光吧。像提灯的小蜗牛一样，虽然走得慢，但每一步都踩在自己的节奏上，心里亮堂堂的。"
  },
  {
    id: 10,
    name: "命运之轮",
    name_en: "Wheel of Fortune",
    image: "card_10.png",
    meaning: "转折 · 幸运 · 惊喜",
    desc: "生活的摩天轮转起来了！低谷之后一定是高处。准备好迎接惊喜吧，好运气正在转角处等你。"
  },
  {
    id: 11,
    name: "正义",
    name_en: "Justice",
    image: "card_11.png",
    meaning: "平衡 · 诚实 · 清晰",
    desc: "心里的天平会告诉你什么是对的。做一个正直而真实的人，今晚你会拥有一个像婴儿般安稳的睡眠。"
  },
  {
    id: 12,
    name: "倒吊人",
    name_en: "The Hanged Man",
    image: "card_12.png",
    meaning: "换个角度 · 等待 · 放松",
    desc: "如果路走不通，不如换个姿势看世界？倒过来看，天空变成了大海。暂停一下没关系，那是为了积蓄跳跃的力量。"
  },
  {
    id: 13,
    name: "死神",
    name_en: "Death",
    image: "card_13.png",
    meaning: "重生 · 告别 · 新芽",
    desc: "不要害怕结束。落叶是为了给新芽腾出位置。和过去那些让你不开心的事说再见吧，崭新的明天正在发芽。"
  },
  {
    id: 14,
    name: "节制",
    name_en: "Temperance",
    image: "card_14.png",
    meaning: "调和 · 治愈 · 恰到好处",
    desc: "不急不躁，慢慢来。把生活里的酸甜苦辣调配成一杯好喝的果汁。保持平衡，你就是最好的生活艺术家。"
  },
  {
    id: 15,
    name: "恶魔",
    name_en: "The Devil",
    image: "card_15.png",
    meaning: "束缚 · 诱惑 · 觉察",
    desc: "是不是太贪吃甜食了？或者沉迷手机太久了？没关系，意识到这一点，轻轻解开那些糖果做的锁链就好。"
  },
  {
    id: 16,
    name: "高塔",
    name_en: "The Tower",
    image: "card_16.png",
    meaning: "突变 · 释放 · 觉醒",
    desc: "有时候，积木塔倒了是为了让你搭个城堡。别怕突如其来的变化，那也许是命运想送你一份意想不到的礼物。"
  },
  {
    id: 17,
    name: "星星",
    name_en: "The Star",
    image: "card_17.png",
    meaning: "希望 · 灵感 · 闪耀",
    desc: "抬头看看夜空，你是最亮的那颗星。无论现在多黑，希望永远都在。许个愿吧，宇宙正在听呢。"
  },
  {
    id: 18,
    name: "月亮",
    name_en: "The Moon",
    image: "card_18.png",
    meaning: "梦境 · 潜意识 · 朦胧",
    desc: "今晚的梦也许会给你答案。不必看清前路的每一步，借着月光，相信直觉，慢慢走，不会迷路的。"
  },
  {
    id: 19,
    name: "太阳",
    name_en: "The Sun",
    image: "card_19.png",
    meaning: "快乐 · 成功 · 活力",
    desc: "快乐得像个孩子一样！没什么大不了的，阳光正好，微风不燥，今天是充满电量、闪闪发光的一天。"
  },
  {
    id: 20,
    name: "审判",
    name_en: "Judgement",
    image: "card_20.png",
    meaning: "召唤 · 觉醒 · 清晰",
    desc: "听到了吗？那是内心深处的号角声。是时候展开翅膀了，告别旧的自己，去拥抱那个更棒的你。"
  },
  {
    id: 21,
    name: "世界",
    name_en: "The World",
    image: "card_21.png",
    meaning: "圆满 · 完成 · 旅程",
    desc: "你已经做得够好了。给自己一个大大的拥抱吧。所有的努力都开出了花，尽情享受这完美的时刻。"
  }
];