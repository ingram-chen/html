# 台灣股票日推薦系統 (Taiwan Daily Stock Recommender)

## 項目概述

台灣股票日推薦系統是一個自動化的股票分析和推薦平台，專門為台灣股市設計。該系統通過整合技術分析、趨勢分析和機器學習算法，為投資者提供每日的股票買賣建議。

### 核心特性

- 🔄 **自動化數據收集**：使用 FinMind API 獲取即時股票數據
- 📊 **多維度分析**：結合移動平均線、RSI、MACD、布林帶等技術指標
- 🎯 **智能推薦**：基於加權評分模型生成可靠的買賣信號
- 💾 **智能緩存**：減少 API 調用，提高系統效率
- 📈 **詳細報告**：生成結構化的分析報告和推薦結果

## 架構說明

系統採用模塊化的三層架構設計：

```
數據獲取層 (Data Fetcher)
       ↓
分析層 (Analyzers)
       ↓
推薦層 (Recommender)
```

### 模塊介紹

#### 1. **數據獲取層 (data_fetcher.py)**
- 從 FinMind API 獲取股票歷史數據
- 支持多個股票代碼的並行獲取
- 實現緩存機制以提高性能
- 自動重試機制處理網絡錯誤

#### 2. **分析層 (analyzers.py)**
負責技術面分析：
- **移動平均線分析**：計算短期和長期移動平均線
- **趨勢識別**：判斷股票上升、下降或橫盤走勢
- **技術指標計算**：
  - RSI (相對強弱指標)：識別超買/超賣狀態
  - MACD (指數平滑異同移動平均線)：識別動量變化
  - 布林帶：識別波動範圍
  - 成交量分析：確認趨勢強度

#### 3. **推薦層 (recommender.py)**
生成最終的投資建議：
- 基於多個技術指標的綜合評分
- 生成「買入」、「賣出」、「持有」的建議
- 計算推薦的置信度水平
- 生成格式化的推薦報告

## 快速開始

### 前置要求

- Python 3.11 或更高版本
- pip 包管理工具
- FinMind API 帳號（免費註冊）

### 安裝步驟

1. **克隆項目倉庫**
   ```bash
   git clone https://github.com/your-repo/taiwan-daily-stock-recommender.git
   cd taiwan-daily-stock-recommender
   ```

2. **創建虛擬環境**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   # 或
   venv\Scripts\activate  # Windows
   ```

3. **安裝依賴**
   ```bash
   pip install -r requirements.txt
   ```

4. **配置環境變量**
   ```bash
   cp .env.example .env
   # 編輯 .env 文件，填入您的 FinMind API Token
   ```

### FinMind 前置條件

#### 獲取 API Token

1. 訪問 [FinMind 官網](https://finmind.github.io/)
2. 使用電子郵件註冊免費帳號
3. 登錄後進入「應用管理」取得 API Token
4. 將 Token 複製到 `.env` 文件的 `FINMIND_API_TOKEN` 欄位

#### 支持的數據類型

FinMind 提供以下數據：
- 每日開高低收成交量
- 技術指標（計算後）
- 上市公司基本資訊
- 融資融券數據

### 基本使用

運行推薦系統：

```bash
python src/main.py
```

### 配置自定義參數

編輯 `.env` 文件調整以下參數：

```env
# 目標股票（逗號分隔的股票代碼）
TARGET_STOCKS=2330,2454,2409,6505

# 分析時間範圍
START_DATE=2024-01-01
END_DATE=2024-12-31

# 技術指標參數
SHORT_MA_WINDOW=20
LONG_MA_WINDOW=50
RSI_PERIOD=14
```

或修改 `config/` 目錄中的配置文件：

- **cache_config.yaml**：緩存和數據更新設置
- **scoring_weights.json**：推薦評分權重配置

## 配置文件說明

### cache_config.yaml

```yaml
cache:
  enabled: true
  ttl_hours: 24  # 緩存有效期（小時）
  storage_path: ".cache/stock_data"
  max_size_mb: 100  # 最大緩存大小（MB）

stock_data:
  update_interval_hours: 4  # 數據更新間隔
  retry_attempts: 3  # 重試次數
  retry_delay_seconds: 5  # 重試延遲
```

### scoring_weights.json

```json
{
  "technical_indicators": {
    "rsi": 0.25,
    "macd": 0.20,
    "moving_average_crossover": 0.20,
    "bollinger_bands": 0.15,
    "volume_trend": 0.20
  },
  "thresholds": {
    "buy_signal_min_score": 0.6,
    "sell_signal_max_score": -0.6,
    "hold_range": [-0.6, 0.6]
  }
}
```

## 輸出示例

### 推薦報告格式

系統生成 JSON 格式的推薦報告：

```json
{
  "date": "2024-12-16",
  "recommendations": [
    {
      "stock_code": "2330",
      "stock_name": "台積電",
      "recommendation": "BUY",
      "confidence": 0.85,
      "score": 0.78,
      "reasoning": {
        "indicators": {
          "rsi": "超賣狀態（<30）",
          "macd": "黃金交叉信號",
          "ma_crossover": "短期均線上穿長期均線"
        },
        "trend": "上升趨勢",
        "support_level": 95.5,
        "resistance_level": 102.3
      },
      "risk_level": "MEDIUM"
    },
    {
      "stock_code": "2454",
      "stock_name": "聯發科",
      "recommendation": "HOLD",
      "confidence": 0.65,
      "score": 0.15,
      "reasoning": {
        "indicators": {
          "rsi": "中性區間（40-60）",
          "macd": "無明確信號",
          "volume": "成交量萎縮"
        },
        "trend": "橫盤走勢"
      },
      "risk_level": "LOW"
    },
    {
      "stock_code": "2409",
      "stock_name": "友達",
      "recommendation": "SELL",
      "confidence": 0.72,
      "score": -0.68,
      "reasoning": {
        "indicators": {
          "rsi": "超買狀態（>70）",
          "macd": "死亡交叉",
          "bb_position": "接近上軌"
        },
        "trend": "下降趨勢",
        "resistance_level": 15.5,
        "support_level": 13.2
      },
      "risk_level": "MEDIUM"
    }
  ],
  "summary": {
    "total_stocks_analyzed": 3,
    "buy_signals": 1,
    "sell_signals": 1,
    "hold_signals": 1,
    "overall_market_sentiment": "中立"
  }
}
```

### 報告輸出位置

推薦報告默認保存在 `output/` 目錄：

```
output/
├── recommendation_2024-12-16.json
├── analysis_2024-12-16.csv
└── report_2024-12-16.html
```

## 指標說明

### RSI (相對強弱指標)
- **範圍**：0-100
- **超買**：> 70（可能面臨回檔）
- **超賣**：< 30（可能反彈）
- **適用性**：識別短期極端走勢

### MACD (指數平滑異同移動平均線)
- **金叉**：快線上穿慢線，看漲信號
- **死叉**：快線下穿慢線，看跌信號
- **適用性**：確認趨勢變化和動量

### 布林帶
- **上軌**：高波動性上限
- **中線**：20日移動平均線
- **下軌**：低波動性下限
- **適用性**：識別支撐和阻力位

### 移動平均線
- **短期 MA20**：反應最近20日趨勢
- **長期 MA50**：反應中期趨勢
- **金叉**：短期均線上穿長期均線，看漲
- **死叉**：短期均線下穿長期均線，看跌

## 項目結構

```
taiwan-daily-stock-recommender/
├── src/                          # 源代碼目錄
│   ├── __init__.py
│   ├── main.py                   # 主程序入口
│   ├── data_fetcher.py           # 數據獲取模塊
│   ├── analyzers.py              # 技術分析模塊
│   └── recommender.py            # 推薦引擎模塊
├── tests/                        # 測試目錄
│   └── __init__.py
├── config/                       # 配置文件
│   ├── cache_config.yaml         # 緩存配置
│   └── scoring_weights.json      # 評分權重
├── output/                       # 輸出結果目錄
│   ├── .gitkeep
│   └── .gitignore
├── .github/workflows/            # GitHub Actions 工作流
│   └── test.yml
├── requirements.txt              # Python 依賴
├── .env.example                  # 環境變量示例
└── README.md                     # 項目文檔
```

## 開發和貢獻

### 運行測試

```bash
pytest tests/ -v
```

### 代碼格式化

```bash
black src tests
isort src tests
```

### 類型檢查

```bash
mypy src
```

### 生成覆蓋率報告

```bash
pytest tests/ --cov=src --cov-report=html
```

## 常見問題 (FAQ)

### Q: FinMind API 是否有調用次數限制？
**A**: 免費帳號通常有調用限制，建議開啟緩存機制。查看 FinMind 官方文檔了解最新限制。

### Q: 如何處理缺失數據？
**A**: 系統自動跳過數據不完整的股票，並在報告中標註。

### Q: 推薦準確性如何？
**A**: 本系統基於技術分析，準確性取決於市場環境。建議結合基本面分析使用。

### Q: 可以自定義分析指標嗎？
**A**: 是的，可以在 `analyzers.py` 中添加自定義指標，並在 `scoring_weights.json` 調整權重。

## 許可證

本項目採用 MIT 許可證。詳見 LICENSE 文件。

## 聯絡方式

如有問題或建議，歡迎提交 Issue 或 Pull Request。

---

**最後更新**: 2024-12-16
**維護者**: Taiwan Stock Recommender Team
