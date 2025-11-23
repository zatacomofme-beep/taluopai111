治愈之书 (Healing Book) - HarmonyOS 塔罗牌应用

项目简介

“治愈之书”是一款基于 HarmonyOS (ArkTS) 开发的治愈系塔罗牌应用。它旨在通过精美的视觉效果、舒缓的交互体验以及充满正能量的卡牌解读，为用户提供每日的心灵指引和情绪疗愈。

本项目演示了 HarmonyOS Stage 模型下的多种高级特性，包括复杂的属性动画、手势交互、数据持久化、AI 服务集成以及桌面服务卡片。

核心功能

每日一抽 (Daily Draw)

每日限抽一次的仪式感体验。

包含拟真的洗牌、发牌和翻转 3D 动画。

基于随机数计算“珍稀度”，不同珍稀度对应不同的翻牌光效（普通白光、稀有蓝光、传说金光等）。

生成每日治愈金句和小任务。

时光流·三牌阵 (Three-Card Spread)

经典的“过去、现在、未来”牌阵解读。

沉浸式的翻牌体验，支持点击卡牌后的“呼吸悬浮”和“Q弹”反馈。

集成 AI 服务（DeepSeek），提供智能化的深度牌面分析。

心情画廊 (Mood Gallery)

记录每日心情（5种情绪状态）及文字备注。

心情画廊模式：以瀑布流网格形式展示历史记录，每张卡片融合了当日抽取的塔罗牌与心情印章，形成独特的回忆墙。

支持心情数据的本地持久化存储。

治愈展览厅 (Collection Gallery)

展示用户已收集的塔罗牌图鉴。

未收集卡片显示为神秘的锁定状态，已收集卡片展示精美大图及珍稀度光晕。

采用全屏沉浸式设计，底部带有优雅的羽化渐变效果。

呼吸冥想 (Breathing Guide)

提供 4-7-8 或 4-2-6 节奏的视觉化呼吸引导。

通过动态缩放的圆环和柔和的色彩变化，帮助用户平复情绪。

桌面服务卡片 (Service Widget)

提供桌面小组件，实时同步今日抽牌结果（卡面、名称、解读）。

支持点击卡片直接跳转至应用主页。

技术栈

开发语言: TypeScript (ArkTS)

开发框架: HarmonyOS SDK (API 9+)

构建工具: Hvigor

关键技术点:

ArkUI: 构建声明式 UI 界面。

动画系统: 使用 animateTo、Curves 实现复杂的属性动画（位移、旋转、缩放、透明度）。

数据持久化: 使用 Preferences 保存用户抽牌记录、心情日记和设置。

AI 集成: 封装 AIService 类，通过 HTTP 请求对接 DeepSeek API 实现流式或文本对话。

Canvas & 截图: 使用 componentSnapshot 生成分享海报，并保存至系统相册。

服务卡片: 实现 FormExtensionAbility，通过 formProvider 更新卡片数据。

目录结构

entry/src/main/ets
├── common                  // 通用工具类
│   ├── AIService.ets       // AI 接口服务
│   ├── BottomNavBar.ets    // 底部悬浮导航栏组件
│   ├── FortuneManager.ets  // 核心数据管理器（单例）
│   ├── ImageSaver.ets      // 图片保存工具
│   ├── ShareHelper.ets     // 系统分享工具
│   └── SoundManager.ets    // (预留) 音效管理
├── dailycard               // 服务卡片模块
│   └── pages
│       └── DailyCardCard.ets // 桌面卡片 UI
├── entryability            // 应用入口 Ability
├── entryformability        // 卡片生命周期管理
├── model                   // 数据模型
│   └── TarotData.ets       // 塔罗牌静态数据定义
├── pages                   // 应用页面
│   ├── Index.ets           // 主页（抽牌、展览厅、分享）
│   ├── MoodPage.ets        // 心情日记（心情画廊）
│   ├── BreathingPage.ets   // 呼吸冥想页
│   └── SpreadPage.ets      // 三牌阵页
└── resources               // 资源文件 (图片、字符串、颜色等)


安装与运行

环境要求:

DevEco Studio 3.1 Release 或更高版本。

HarmonyOS SDK API 9 或更高版本。

配置:

确保 local.properties 或 FortuneManager.ets 中配置了正确的 SDK 路径（通常由 IDE 自动处理）。

AI 功能: 若要使用深度解读功能，需在 AIService.ets 中配置有效的 API Key（或在应用内设置）。

运行:

使用模拟器或真机连接 DevEco Studio。

点击 "Run 'entry'" 即可安装体验。

注意事项

权限: 应用涉及保存图片功能，需在 module.json5 中声明 ohos.permission.WRITE_IMAGEVIDEO 等权限（视系统版本而定）。

兼容性: 代码主要针对 Stage 模型编写，部分 API 可能需要 API 9+ 支持。

贡献

欢迎提交 Issue 或 Pull Request 来改进这个
