import 'dart:convert';

class ProfitRecord {
  final String id;
  final String productName;
  final String platform; // 淘宝/天猫, 拼多多, 抖音, 自定义
  final double sellingPrice; // 售价 (元)
  final double costPrice; // 拿货成本 (元)
  final double expressFee; // 发货快递费 (元)
  final double packFee; // 包材与人工费 (元)
  final double commissionRate; // 平台扣点 (%)
  final double shippingInsurance; // 运费险 (元/单)
  final double returnRate; // 预估退货率 (%)
  final double promoFee; // 单单推广费/广告费 (元)
  final DateTime createdAt;

  ProfitRecord({
    required this.id,
    required this.productName,
    required this.platform,
    required this.sellingPrice,
    required this.costPrice,
    required this.expressFee,
    required this.packFee,
    required this.commissionRate,
    required this.shippingInsurance,
    required this.returnRate,
    required this.promoFee,
    required this.createdAt,
  });

  // --- 核心数学计算指标 ---

  /// 平台扣点金额 (元) = 售价 * 扣点比例
  double get commissionAmount => sellingPrice * (commissionRate / 100);

  /// 基础单笔毛利 (不计退货损耗与广告费)
  /// 毛利 = 售价 - 平台扣点 - 拿货成本 - 快递 - 包材 - 运费险
  double get grossProfit {
    return sellingPrice - commissionAmount - costPrice - expressFee - packFee - shippingInsurance;
  }

  /// 毛利率 (%) = (毛利 / 售价) * 100
  double get grossMargin {
    if (sellingPrice <= 0) return 0.0;
    return (grossProfit / sellingPrice) * 100;
  }

  /// 真实净利润 (元/发货单)：计入退货率导致的真实损耗 + 推广费
  /// 数学逻辑：
  /// - 成功签收单 (1 - returnRate)：产生有效营收 [售价 * (1 - 扣点) - 拿货成本]
  /// - 所有发货单 (100%)：无论是否退货，快递费、包材费、运费险、推广费均已真实沉没支出
  ///   即：单单真实净利 = (1 - r) * [售价*(1-扣点) - 货本] - (快递 + 包材 + 运费险 + 推广)
  double get realNetProfit {
    final double r = (returnRate / 100).clamp(0.0, 1.0);
    final double effectiveNetRevenue = (1.0 - r) * (sellingPrice * (1.0 - commissionRate / 100) - costPrice);
    final double fixedDispatchedCost = expressFee + packFee + shippingInsurance + promoFee;
    return effectiveNetRevenue - fixedDispatchedCost;
  }

  /// 真实净利率 (%) = (真实净利润 / 售价) * 100
  double get netMargin {
    if (sellingPrice <= 0) return 0.0;
    return (realNetProfit / sellingPrice) * 100;
  }

  /// 保本单单最大允许推广花费 (元)
  /// 当净利为 0 时：C_ad_max = (1 - r) * [售价*(1-扣点) - 货本] - (快递 + 包材 + 运费险)
  double get maxAllowableAdSpend {
    final double r = (returnRate / 100).clamp(0.0, 1.0);
    final double effectiveNetRevenue = (1.0 - r) * (sellingPrice * (1.0 - commissionRate / 100) - costPrice);
    final double baseDispatchedCost = expressFee + packFee + shippingInsurance;
    return effectiveNetRevenue - baseDispatchedCost;
  }

  /// 保本投产比 (Breakeven ROI) = 售价 / 保本最大允许推广花费
  /// - 若保本最大允许推广费 <= 0，代表不打广告本身也已经亏损，无保本 ROI
  double get breakevenRoi {
    final double maxAd = maxAllowableAdSpend;
    if (maxAd <= 0 || sellingPrice <= 0) {
      return 0.0; // 无法保本或售价非法
    }
    return sellingPrice / maxAd;
  }

  // --- 复制账单纯文本格式化 ---
  String toShareableBill() {
    final roiText = breakevenRoi > 0 ? breakevenRoi.toStringAsFixed(2) : "不可保本(成本倒挂)";
    return '''
【电商成本与利润测算清单】
-----------------------------
📦 商品名称: ${productName.isEmpty ? '未命名商品' : productName}
🏷 所属平台: $platform
💰 销售定价: ¥${sellingPrice.toStringAsFixed(2)}
📉 拿货成本: ¥${costPrice.toStringAsFixed(2)}
🚚 快递运费: ¥${expressFee.toStringAsFixed(2)}
📦 包材人工: ¥${packFee.toStringAsFixed(2)}
🏛 平台扣点: ${commissionRate.toStringAsFixed(1)}% (¥${commissionAmount.toStringAsFixed(2)})
🛡 运费险费: ¥${shippingInsurance.toStringAsFixed(2)}
🔄 预估退货: ${returnRate.toStringAsFixed(1)}%
📢 单单推广: ¥${promoFee.toStringAsFixed(2)}
-----------------------------
📊【核心经营指标】
▪ 单笔毛利: ¥${grossProfit.toStringAsFixed(2)} (毛利率: ${grossMargin.toStringAsFixed(1)}%)
▪ 真实净利: ¥${realNetProfit.toStringAsFixed(2)} (净利率: ${netMargin.toStringAsFixed(1)}%)
🎯 保本投产比 (ROI): $roiText
*(提示: 付费推广时 ROI 高于此保本线即可实现正向盈利)*
-----------------------------
⏰ 测算时间: ${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}
''';
  }

  // --- 序列化 / 反序列化 ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'platform': platform,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'expressFee': expressFee,
      'packFee': packFee,
      'commissionRate': commissionRate,
      'shippingInsurance': shippingInsurance,
      'returnRate': returnRate,
      'promoFee': promoFee,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProfitRecord.fromMap(Map<String, dynamic> map) {
    return ProfitRecord(
      id: map['id'] ?? '',
      productName: map['productName'] ?? '',
      platform: map['platform'] ?? '自定义',
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      expressFee: (map['expressFee'] as num?)?.toDouble() ?? 0.0,
      packFee: (map['packFee'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0.0,
      shippingInsurance: (map['shippingInsurance'] as num?)?.toDouble() ?? 0.0,
      returnRate: (map['returnRate'] as num?)?.toDouble() ?? 0.0,
      promoFee: (map['promoFee'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfitRecord.fromJson(String source) =>
      ProfitRecord.fromMap(json.decode(source));
}
