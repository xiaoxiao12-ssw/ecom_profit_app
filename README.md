# 电商成本与利润分析助手 (E-Commerce Profit Analysis App)

一款专为电商运营打造的精细化成本核算与利润决策安卓 App，支持手机与平板自适应布局。采用纯本地离线计算与存储（`shared_preferences`），安全无广告、无需联网、绝无任何预置虚假数据。

---

## 🌟 核心功能一览

1. **多平台参数快捷预设与灵活测算**
   - 快捷支持 **淘宝/天猫**、**拼多多**、**抖音商城** 及 **自定义** 四大经营场景。
   - 切换平台时自动预置平台常见扣点率与运费险参考基准，所有参数随时可手动修改。
2. **多维度真实经营指标动态计算**
   - **基础单笔毛利 & 毛利率**：剥离扣点与固定杂费后的单笔基础收益。
   - **真实单单净利润 & 净利率**：**真实计入退货率损耗**（发货快递费、退货运费险、包材人工费的实际沉没成本），绝不粉饰账面利润。
   - **保本投产比 (Breakeven ROI)**：精准推导在当前成本和退货率下，付费推广（直通车/千川/多多搜索）的保本线，直观提示高于此值即盈利。
   - **最大允许广告支出**：单单推广费上限。
3. **阶梯定价方案多维横向对比**
   - 快速对比 **日常标价**、**大促活动价**、**秒杀冲量价** 3 个定价区间的净利润与 ROI，标注健康度（稳健盈利/薄利冲量/成本倒挂），辅助科学定标价。
4. **本地历史账单管理与一键分享**
   - 支持多方案存储、模糊搜索、平台筛选、回填重新编辑及左滑删除。
   - 具备「一键复制账单」功能，生成工整规范的纯文本清单，方便发给团队或合伙人。

---

## 🚀 云端自动化打包 (GitHub Actions)

本项目已配置完整的 `.github/workflows/build-apk.yml`，**本地电脑无需配置 Flutter SDK 或 Android Studio**，直接通过 GitHub 云端免费打包编译出 Release 版 APK！

### 极简 3 步打包指引：

1. **在 GitHub 新建一个空仓库**（例如命名为 `ecom_profit_app`，设为 Public 或 Private 均可）。
2. **在本地 `ecom_profit_app` 文件夹下打开终端执行**：
   ```bash
   git init
   git add .
   git commit -m "feat: initial commit of ecom profit app"
   git branch -M main
   git remote add origin https://github.com/你的用户名/ecom_profit_app.git
   git push -u origin main
   ```
3. **前往 GitHub 仓库页面下载 APK**：
   - 点击顶部的 **Actions** 标签页；
   - 可以看到正在运行的 **Build Android APK** 工作流；
   - 等待约 3~5 分钟构建完成（显示绿色对勾）；
   - 点击进入这次运行记录，在页面底部的 **Artifacts** 区域即可一键下载 **`ecom-profit-app-release`** 安装包！
