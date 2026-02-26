require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { GoogleGenAI } = require("@google/genai");
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const JWT_SECRET = process.env.JWT_SECRET || "gamepulse_jwt_secret_2024";
const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || "gamepulse_admin_jwt_secret_2024_secure";

const app = express();
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});
app.use(express.json());

function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  if (!token) {
    return res.status(401).json({ success: false, message: "Требуется авторизация" });
  }
  jwt.verify(token, JWT_SECRET, (err, payload) => {
    if (err) {
      return res.status(403).json({ success: false, message: "Токен недействителен или истёк" });
    }
    req.user = payload;
    next();
  });
}

function adminAuth(req, res, next) {
  const token = req.headers["authorization"]?.split(" ")[1];
  if (!token) {
    return res.status(401).json({ success: false, message: "Требуется авторизация администратора" });
  }
  try {
    const decoded = jwt.verify(token, ADMIN_JWT_SECRET);
    if (!decoded.isAdmin) {
      return res.status(403).json({ success: false, message: "Доступ запрещён" });
    }
    req.admin = decoded;
    next();
  } catch {
    res.status(401).json({ success: false, message: "Токен администратора недействителен" });
  }
}

mongoose
  .connect("mongodb://localhost:27017/gamepulse", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(async () => {
    console.log("✅ MongoDB подключена");
    await seedAdmin();
    await loadCustomData();
  })
  .catch((err) => console.error("❌ Ошибка подключения:", err));

const AI_MODEL = process.env.GEMINI_MODEL || "gemini-3-flash-preview";

const UserSchema = new mongoose.Schema({
  username: String,
  email: String,
  password: String,
  isBlocked: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  pcSpecs: {
    cpu: String,
    gpu: String,
    ram: String,
    storage: String,
    os: String,
  },
  checkHistory: [
    {
      game: String,
      fps: Number,
      status: String,
      checkedAt: { type: Date, default: Date.now },
    },
  ],
});

async function geminiChat({ systemInstruction, history, temperature = 0.7, maxOutputTokens = 800 }) {
  const contents = (history || [])
    .filter(m => m && m.role && m.role !== "system")
    .map(m => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: String(m.content ?? "") }],
    }));

  const resp = await ai.models.generateContent({
    model: AI_MODEL,
    contents,
    config: {
      systemInstruction: systemInstruction || "",
      temperature,
      maxOutputTokens,
    },
  });

  const candidates = resp?.candidates || resp?.response?.candidates || [];
  const parts = candidates?.[0]?.content?.parts || [];

  const finishReason = candidates?.[0]?.finishReason;

  let text = parts
    .map(p => (typeof p?.text === "string" ? p.text : ""))
    .join("")
    .trim();

  if (!text) {
    const t1 = typeof resp?.text === "string" ? resp.text : "";
    const t2 = typeof resp?.response?.text === "function" ? resp.response.text() : "";
    text = (t1 || t2 || "").toString().trim();
  }

  return text;
}


const User = mongoose.model("User", UserSchema);

const AdminSchema = new mongoose.Schema({
  email: String,
  password: String,
  name: String,
});
const Admin = mongoose.model("Admin", AdminSchema);

const CustomGameSchema = new mongoose.Schema({
  title: String,
  minimum: { cpu: [String], gpu: [String], ram: String },
  recommended: { cpu: [String], gpu: [String], ram: String },
  high: { cpu: [String], gpu: [String], ram: String },
});
const CustomGame = mongoose.model("CustomGame", CustomGameSchema);

const CustomComponentSchema = new mongoose.Schema({
  type: String,
  name: String,
  price: Number,
  link: String,
  performance: Number,
  budget: String,
});
const CustomComponent = mongoose.model("CustomComponent", CustomComponentSchema);

async function seedAdmin() {
  try {
    const adminEmail = process.env.ADMIN_EMAIL || "admin@gamepulse.com";
    const adminPassword = process.env.ADMIN_PASSWORD || "admin123";
    const existing = await Admin.findOne({ email: adminEmail });
    if (!existing) {
      const hashedPassword = await bcrypt.hash(adminPassword, 10);
      await new Admin({
        email: adminEmail,
        password: hashedPassword,
        name: "Администратор",
      }).save();
      console.log(`✅ Админ создан: ${adminEmail}`);
    }
  } catch (err) {
    console.error("Ошибка создания админа:", err);
  }
}

async function loadCustomData() {
  try {
    const customGames = await CustomGame.find();
    for (const game of customGames) {
      gamesDatabase[game.title] = {
        minimum: { cpu: game.minimum.cpu, gpu: game.minimum.gpu, ram: game.minimum.ram },
        recommended: { cpu: game.recommended.cpu, gpu: game.recommended.gpu, ram: game.recommended.ram },
        high: { cpu: game.high.cpu, gpu: game.high.gpu, ram: game.high.ram },
      };
    }
    const customComponents = await CustomComponent.find();
    for (const comp of customComponents) {
      if (!componentPrices[comp.type]) componentPrices[comp.type] = {};
      componentPrices[comp.type][comp.name] = {
        price: comp.price,
        link: comp.link,
        performance: comp.performance,
        budget: comp.budget,
      };
    }
    if (customGames.length > 0 || customComponents.length > 0) {
      console.log(`✅ Загружено ${customGames.length} доп. игр, ${customComponents.length} доп. компонентов`);
    }
  } catch (err) {
    console.error("Ошибка загрузки данных:", err);
  }
}
const gamesDatabase = {
  "Counter-Strike 2": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "Intel i7-13620h", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "NVIDIA RTX 3060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i9-14900k", "AMD Ryzen 7 5700x3d", "AMD Ryzen 9 9950x3d"],
      gpu: ["NVIDIA RTX 4060", "AMD RX 7800 XT"],
      ram: "32 GB",
    },
  },
  "PUBG: Battlegrounds": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d", "Intel i9-14900k", "AMD Ryzen 9 9950x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060", "AMD RX 7800 XT"],
      ram: "16 GB",
    },
  },
  "Minecraft": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060"],
      ram: "8 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060"],
      ram: "16 GB",
    },
  },
  "Valorant": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "8 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060"],
      ram: "16 GB",
    },
  },
  "Cyberpunk 2077": {
    minimum: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    recommended: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "AMD RX 7800 XT"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i9-14900k", "AMD Ryzen 9 9950x3d"],
      gpu: ["NVIDIA RTX 4060", "AMD RX 7800 XT"],
      ram: "32 GB",
    },
  },
  "Red Dead Redemption 2": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 4060", "AMD RX 7800 XT"],
      ram: "32 GB",
    },
  },
  "Fortnite": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060"],
      ram: "16 GB",
    },
  },
  "GTA V": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "AMD RX 7800 XT"],
      ram: "16 GB",
    },
  },
  "The Witcher 3": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060"],
      ram: "16 GB",
    },
  },
  "Apex Legends": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060"],
      ram: "16 GB",
    },
  },
  "Dota 2": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060"],
      ram: "8 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060"],
      ram: "16 GB",
    },
  },
  "League of Legends": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060"],
      ram: "8 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060"],
      ram: "16 GB",
    },
  },
  "Overwatch 2": {
    minimum: {
      cpu: ["Intel i3-12100", "AMD Ryzen 3 3200g"],
      gpu: ["NVIDIA GTX 1650"],
      ram: "8 GB",
    },
    recommended: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "NVIDIA RTX 4060"],
      ram: "16 GB",
    },
  },
  "Elden Ring": {
    minimum: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    recommended: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "AMD RX 7800 XT"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i9-14900k", "AMD Ryzen 9 9950x3d"],
      gpu: ["NVIDIA RTX 4060", "AMD RX 7800 XT"],
      ram: "32 GB",
    },
  },
  "Starfield": {
    minimum: {
      cpu: ["Intel i5-12400", "AMD Ryzen 5 5600x"],
      gpu: ["NVIDIA RTX 2060", "AMD RX 6600"],
      ram: "16 GB",
    },
    recommended: {
      cpu: ["Intel i7-13620h", "AMD Ryzen 7 5700x3d"],
      gpu: ["NVIDIA RTX 3060", "AMD RX 7800 XT"],
      ram: "16 GB",
    },
    high: {
      cpu: ["Intel i9-14900k", "AMD Ryzen 9 9950x3d"],
      gpu: ["NVIDIA RTX 4060", "AMD RX 7800 XT"],
      ram: "32 GB",
    },
  },
};
const componentPrices = {
  cpu: {
    "Intel i3-12100": { 
      price: 120, 
      link: "https://www.dns-shop.ru/search/?q=Intel+Core+i3-12100",
      performance: 100,
      budget: "low"
    },
    "Intel i5-12400": { 
      price: 180, 
      link: "https://www.dns-shop.ru/search/?q=Intel+Core+i5-12400",
      performance: 150,
      budget: "medium"
    },
    "Intel i7-13620h": { 
      price: 300, 
      link: "https://www.dns-shop.ru/search/?q=Intel+Core+i7-13620H",
      performance: 220,
      budget: "medium"
    },
    "Intel i9-14900k": { 
      price: 600, 
      link: "https://www.dns-shop.ru/search/?q=Intel+Core+i9-14900K",
      performance: 320,
      budget: "high"
    },
    "AMD Ryzen 3 3200g": { 
      price: 90, 
      link: "https://www.dns-shop.ru/search/?q=AMD+Ryzen+3+3200G",
      performance: 90,
      budget: "low"
    },
    "AMD Ryzen 5 5600x": { 
      price: 200, 
      link: "https://www.dns-shop.ru/search/?q=AMD+Ryzen+5+5600X",
      performance: 180,
      budget: "medium"
    },
    "AMD Ryzen 7 5700x3d": { 
      price: 300, 
      link: "https://www.dns-shop.ru/search/?q=AMD+Ryzen+7+5700X3D",
      performance: 260,
      budget: "medium"
    },
    "AMD Ryzen 9 9950x3d": { 
      price: 700, 
      link: "https://www.dns-shop.ru/search/?q=AMD+Ryzen+9+9950X3D",
      performance: 350,
      budget: "high"
    },
  },
  gpu: {
    "NVIDIA GTX 1650": { 
      price: 180, 
      link: "https://www.dns-shop.ru/search/?q=NVIDIA+GeForce+GTX+1650",
      performance: 100,
      budget: "low"
    },
    "NVIDIA RTX 2060": { 
      price: 300, 
      link: "https://www.dns-shop.ru/search/?q=NVIDIA+GeForce+RTX+2060",
      performance: 150,
      budget: "medium"
    },
    "NVIDIA RTX 3060": { 
      price: 400, 
      link: "https://www.dns-shop.ru/search/?q=NVIDIA+GeForce+RTX+3060",
      performance: 200,
      budget: "medium"
    },
    "NVIDIA RTX 4060": { 
      price: 500, 
      link: "https://www.dns-shop.ru/search/?q=NVIDIA+GeForce+RTX+4060",
      performance: 250,
      budget: "high"
    },
    "AMD RX 6600": { 
      price: 280, 
      link: "https://www.dns-shop.ru/search/?q=AMD+Radeon+RX+6600",
      performance: 160,
      budget: "medium"
    },
    "AMD RX 7800 XT": { 
      price: 550, 
      link: "https://www.dns-shop.ru/search/?q=AMD+Radeon+RX+7800+XT",
      performance: 280,
      budget: "high"
    },
  },
  ram: {
    "8 GB": { 
      price: 30, 
      link: "https://www.dns-shop.ru/catalog/17a8a01d16404e77/operativnaya-pamyat/?order=1&stock=2&f=8gb",
      performance: 100,
      budget: "low"
    },
    "16 GB": { 
      price: 50, 
      link: "https://www.dns-shop.ru/catalog/17a8a01d16404e77/operativnaya-pamyat/?order=1&stock=2&f=16gb",
      performance: 150,
      budget: "medium"
    },
    "32 GB": { 
      price: 100, 
      link: "https://www.dns-shop.ru/catalog/17a8a01d16404e77/operativnaya-pamyat/?order=1&stock=2&f=32gb",
      performance: 200,
      budget: "medium"
    },
    "64 GB": { 
      price: 200, 
      link: "https://www.dns-shop.ru/catalog/17a8a01d16404e77/operativnaya-pamyat/?order=1&stock=2&f=64gb",
      performance: 250,
      budget: "high"
    },
  },
};
function getComponentPerformance(component, type) {
  const prices = componentPrices[type];
  if (prices && prices[component]) {
    return prices[component].performance || 100;
  }
  return 100;
}
function calculateRealFPS(userPC, gameTitle) {
  const cpuPerf = getComponentPerformance(userPC.cpu, 'cpu');
  const gpuPerf = getComponentPerformance(userPC.gpu, 'gpu');
  const ramPerf = getComponentPerformance(userPC.ram, 'ram');
    const baseScore = (gpuPerf * 0.5) + (cpuPerf * 0.3) + (ramPerf * 0.2);
    const gameMultipliers = {
    "Counter-Strike 2": 1.2,
    "PUBG: Battlegrounds": 0.8,
    "Minecraft": 1.5,
    "Valorant": 1.3,
    "Cyberpunk 2077": 0.6,
    "Red Dead Redemption 2": 0.7,
    "Fortnite": 1.1,
    "GTA V": 1.0,
    "The Witcher 3": 0.9,
    "Apex Legends": 1.0,
    "Dota 2": 1.4,
    "League of Legends": 1.4,
    "Overwatch 2": 1.2,
    "Elden Ring": 0.8,
    "Starfield": 0.7,
  };
  
  const multiplier = gameMultipliers[gameTitle] || 1.0;
  return Math.round(baseScore * multiplier);
}

function checkCompatibility(userPC, requirements, gameTitle) {
  const cpuPerf = getComponentPerformance(userPC.cpu, 'cpu');
  const gpuPerf = getComponentPerformance(userPC.gpu, 'gpu');
  const ramValue = parseInt(userPC.ram);

  let status = "unknown";
  let level = "minimum";
  let message = "";
  
  const highCpuMatch = requirements.high.cpu.includes(userPC.cpu);
  const highGpuMatch = requirements.high.gpu.includes(userPC.gpu);
  const highRamValue = parseInt(requirements.high.ram);
  
  const estimatedFPS = calculateRealFPS(userPC, gameTitle);
  
  if (estimatedFPS >= 120) {
    status = "excellent";
    level = "high";
    message = "🔥 Отлично! 120+ FPS";
  } else if (estimatedFPS >= 60) {
    status = "good";
    level = "recommended";
    message = "👍 Хорошо! 60+ FPS";
  } else if (estimatedFPS >= 30) {
    status = "playable";
    level = "minimum";
    message = "⚠️ Играбельно, 30-60 FPS";
  } else {
    status = "insufficient";
    level = "below_minimum";
    message = "❌ Менее 30 FPS";
  }

  return {
    status,
    level,
    message,
    estimatedFPS,
    cpuPerformance: cpuPerf,
    gpuPerformance: gpuPerf,
    ramPerformance: ramValue,
  };
}


app.post("/register", async (req, res) => {
  const { username, email, password } = req.body;

  if (!password || password.length < 8) {
    return res.status(400).json({
      message: "Пароль должен содержать минимум 8 символов"
    });
  }

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email уже зарегистрирован" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({
      username,
      email,
      password: hashedPassword,
      pcSpecs: {},
    });

    await newUser.save();
    res.status(201).json({ message: "Регистрация успешна" });
  } catch (err) {
    console.error("Ошибка регистрации:", err);
    res.status(500).json({ message: "Ошибка регистрации" });
  }
});

app.post("/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.json({ success: false, message: "Неверный email или пароль" });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.json({ success: false, message: "Неверный email или пароль" });
    }

    const token = jwt.sign(
      { email: user.email, userId: user._id.toString() },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      success: true,
      message: "Успешный вход",
      token,
      user: {
        username: user.username,
        email: user.email,
        pcSpecs: user.pcSpecs,
      },
    });
  } catch (err) {
    console.error("Ошибка входа:", err);
    res.json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/add-pc", authenticateToken, async (req, res) => {
  const { email, cpu, gpu, ram, storage, os } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    user.pcSpecs = { cpu, gpu, ram, storage, os };
    await user.save();
    res.json({ message: "Характеристики ПК обновлены" });
  } catch (err) {
    console.error("Ошибка обновления ПК:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

app.get("/user/:email", authenticateToken, async (req, res) => {
  try {
    const user = await User.findOne({ email: req.params.email });
    if (!user)
      return res
        .status(404)
        .json({ success: false, message: "Пользователь не найден" });

    res.json({ success: true, user });
  } catch (err) {
    console.error("Ошибка при получении профиля:", err);
    res
      .status(500)
      .json({ success: false, message: "Ошибка при получении данных пользователя" });
  }
});

// Update profile (username)
app.post("/update-profile", authenticateToken, async (req, res) => {
  const { email, username } = req.body;
  if (!email || !username || username.trim().length === 0) {
    return res.status(400).json({ success: false, message: "Имя пользователя не может быть пустым" });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: "Пользователь не найден" });
    user.username = username.trim();
    await user.save();
    res.json({ success: true, message: "Имя успешно обновлено", user });
  } catch (err) {
    console.error("Ошибка update-profile:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// Change password (requires old password verification)
app.post("/change-password", authenticateToken, async (req, res) => {
  const { email, oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) {
    return res.status(400).json({ success: false, message: "Заполните все поля" });
  }
  if (newPassword.length < 8) {
    return res.status(400).json({ success: false, message: "Новый пароль должен содержать минимум 8 символов" });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: "Пользователь не найден" });

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: "Неверный текущий пароль" });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();
    res.json({ success: true, message: "Пароль успешно изменён" });
  } catch (err) {
    console.error("Ошибка change-password:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/check-game-compatibility", authenticateToken, async (req, res) => {
  const { email, gameTitle } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user || !user.pcSpecs.cpu) {
      return res.status(400).json({
        success: false,
        message: "Добавьте характеристики ПК",
      });
    }

    const gameRequirements = gamesDatabase[gameTitle];
    if (!gameRequirements) {
      return res.status(400).json({
        success: false,
        message: "Игра не найдена",
      });
    }

    const compatibility = checkCompatibility(user.pcSpecs, gameRequirements, gameTitle);

    // Save to check history (keep last 20 entries)
    user.checkHistory.unshift({
      game: gameTitle,
      fps: compatibility.estimatedFPS,
      status: compatibility.status,
      checkedAt: new Date(),
    });
    if (user.checkHistory.length > 20) {
      user.checkHistory = user.checkHistory.slice(0, 20);
    }
    await user.save();

    res.json({
      success: true,
      compatibility,
      userPC: user.pcSpecs,
      gameRequirements: {
        minimum: gameRequirements.minimum,
        recommended: gameRequirements.recommended,
      }
    });
  } catch (err) {
    console.error("Ошибка проверки:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/forgot-password", async (req, res) => {
  const { email, newPassword } = req.body;

  if (!newPassword || newPassword.length < 8) {
    return res.status(400).json({
      success: false,
      message: "Новый пароль должен содержать минимум 8 символов",
    });
  }

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Пользователь с таким email не найден",
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.json({
      success: true,
      message: "Пароль успешно изменён. Войдите с новым паролем.",
    });
  } catch (err) {
    console.error("Ошибка восстановления пароля:", err);
    res.status(500).json({
      success: false,
      message: "Ошибка сервера",
    });
  }
});

app.post("/upgrade-recommendations", authenticateToken, async (req, res) => {
  const { email, gameTitle, budget = "medium" } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user || !user.pcSpecs.cpu) {
      return res.status(400).json({
        success: false,
        message: "Добавьте характеристики ПК",
      });
    }

    const gameRequirements = gamesDatabase[gameTitle];
    if (!gameRequirements) {
      return res.status(400).json({
        success: false,
        message: "Игра не найдена",
      });
    }

    const recommendations = [];
    let totalCost = 0;

    const currentCpuPerf = getComponentPerformance(user.pcSpecs.cpu, 'cpu');
    const currentGpuPerf = getComponentPerformance(user.pcSpecs.gpu, 'gpu');

    const selectComponentByBudget = (components, currentPerf, type, targetBudget) => {
      let bestComponent = null;
      let bestPerf = currentPerf;
      
      const budgetFilter = {
        "low": ["low", "medium"],
        "medium": ["medium"],
        "high": ["medium", "high"]
      };
      
      const allowedBudgets = budgetFilter[targetBudget] || ["medium"];
      
      for (const component of components) {
        const compData = componentPrices[type][component];
        if (!compData) continue;
        
        const perf = compData.performance;
        const compBudget = compData.budget;
        
        if (allowedBudgets.includes(compBudget) && perf > bestPerf) {
          bestPerf = perf;
          bestComponent = component;
        }
      }
      
      return bestComponent;
    };

    if (!gameRequirements.high.cpu.includes(user.pcSpecs.cpu)) {
      const bestCPU = selectComponentByBudget(
        gameRequirements.high.cpu, 
        currentCpuPerf, 
        'cpu',
        budget
      );
      
      if (bestCPU && bestCPU !== user.pcSpecs.cpu) {
        const cpuPrice = componentPrices.cpu[bestCPU];
        recommendations.push({
          component: "Процессор",
          current: user.pcSpecs.cpu,
          recommended: bestCPU,
          price: cpuPrice.price,
          link: cpuPrice.link,
          priority: "high",
          budgetCategory: cpuPrice.budget
        });
        totalCost += cpuPrice.price;
      }
    }

    if (!gameRequirements.high.gpu.includes(user.pcSpecs.gpu)) {
      const bestGPU = selectComponentByBudget(
        gameRequirements.high.gpu, 
        currentGpuPerf, 
        'gpu',
        budget
      );
      
      if (bestGPU && bestGPU !== user.pcSpecs.gpu) {
        const gpuPrice = componentPrices.gpu[bestGPU];
        recommendations.push({
          component: "Видеокарта",
          current: user.pcSpecs.gpu,
          recommended: bestGPU,
          price: gpuPrice.price,
          link: gpuPrice.link,
          priority: "high",
          budgetCategory: gpuPrice.budget
        });
        totalCost += gpuPrice.price;
      }
    }

    const currentRamValue = parseInt(user.pcSpecs.ram);
    const requiredRamValue = parseInt(gameRequirements.high.ram);
    
    if (currentRamValue < requiredRamValue) {
      const recommendedRAM = gameRequirements.high.ram;
      const ramPrice = componentPrices.ram[recommendedRAM];
      
      if (budget === "low" && ramPrice.budget === "high") {
        const affordableRAM = "16 GB";
        const affordablePrice = componentPrices.ram[affordableRAM];
        recommendations.push({
          component: "Оперативная память",
          current: user.pcSpecs.ram,
          recommended: affordableRAM,
          price: affordablePrice.price,
          link: affordablePrice.link,
          priority: "medium",
          budgetCategory: affordablePrice.budget
        });
        totalCost += affordablePrice.price;
      } else {
        recommendations.push({
          component: "Оперативная память",
          current: user.pcSpecs.ram,
          recommended: recommendedRAM,
          price: ramPrice.price,
          link: ramPrice.link,
          priority: "medium",
          budgetCategory: ramPrice.budget
        });
        totalCost += ramPrice.price;
      }
    }

    const budgetMessages = {
      "low": "💰 Бюджетные рекомендации",
      "medium": "💎 Оптимальные рекомендации",
      "high": "🔥 Премиум рекомендации"
    };

    res.json({
      success: true,
      recommendations,
      totalCost,
      budget,
      budgetMessage: budgetMessages[budget],
      message: recommendations.length === 0
        ? "🎉 Ваш ПК уже идеален для этой игры!"
        : `🔧 Рекомендуем улучшить ${recommendations.length} компонент(а)`,
    });
  } catch (err) {
    console.error("Ошибка получения рекомендаций:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/ai-upgrade-explanation", authenticateToken, async (req, res) => {
  const { email, gameTitle, recommendation, userQuestion, messages = [] } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ success: false, message: "Пользователь не найден" });
    }

  const systemPrompt = `
Ты эксперт по компьютерному железу.
Отвечай кратко, чётко и профессионально.
5-7 абзацев максимум.
Без лишней воды.
Структурируй ответ.
Объясни:
1) прирост FPS,
2) стабильность,
3) стоит ли апгрейд,
4) альтернатива.
Ответ должен быть завершенным и логически законченным.
Не обрывай предложения.
`;
    const chatHistory = [];
    if (Array.isArray(messages)) {
      for (const msg of messages) {
        if (msg && msg.text) {
          chatHistory.push({
            role: msg.isUser ? "user" : "assistant",
            content: String(msg.text),
          });
        }
      }
    }

    chatHistory.push({ role: "user", content: String(userQuestion || "Расскажи об этом компоненте") });

    let explanation = await geminiChat({
      systemInstruction: systemPrompt,
      history: chatHistory,
      temperature: 0.6,
      maxOutputTokens: 1500,
    });

    if (explanation && explanation.length > 100) {
      const last = explanation.trim().slice(-1);
      const looksCut =
        ![".", "!", "?", "…"].includes(last);

      if (looksCut) {
        const continuation = await geminiChat({
          systemInstruction: systemPrompt,
          history: [
            ...chatHistory,
            { role: "assistant", content: explanation },
            { role: "user", content: "Продолжи ответ полностью и закончи мысль." },
          ],
          maxOutputTokens: 1000,
        });

        explanation = `${explanation}\n${continuation}`.trim();
      }
    }

    return res.json({
      success: true,
      source: "gemini",
      explanation: explanation,
    });

  } catch (err) {
    console.error("Ошибка ИИ-объяснения:", err);

    const status = err?.status || err?.code;
    const msg = String(err?.message || err);

    if (status === 429 || msg.includes("RESOURCE_EXHAUSTED") || msg.includes("Quota exceeded")) {
      return res.status(429).json({
        success: false,
        source: "gemini",
        code: "QUOTA_EXCEEDED",
        message: "Gemini лимит/квота бітті. Кейінірек қайталап көр немесе billing қос.",
      });
    }

    return res.status(500).json({
      success: false,
      source: "gemini",
      code: "AI_ERROR",
      message: "AI сервер жағында қате шықты",
      error: msg,
    });
  }

});

app.post("/performance-graph", authenticateToken, async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user || !user.pcSpecs.cpu) {
      return res.status(400).json({
        success: false,
        message: "Добавьте характеристики ПК",
      });
    }

    const performanceData = [];
    
    for (const [gameTitle, requirements] of Object.entries(gamesDatabase)) {
      const compatibility = checkCompatibility(user.pcSpecs, requirements, gameTitle);
      performanceData.push({
        game: gameTitle,
        fps: compatibility.estimatedFPS,
        status: compatibility.status,
        level: compatibility.level
      });
    }

    performanceData.sort((a, b) => b.fps - a.fps);

    res.json({
      success: true,
      performanceData,
      userPC: user.pcSpecs
    });
  } catch (err) {
    console.error("Ошибка получения данных графика:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/ai-game-recommendations", authenticateToken, async (req, res) => {
  const { email, preferences } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user || !user.pcSpecs.cpu) {
      return res.status(400).json({
        success: false,
        message: "Добавьте характеристики ПК",
      });
    }

    const availableGames = Object.keys(gamesDatabase).join(", ");
    
    const prompt = `Ты - эксперт по видеоиграм. 
    
Характеристики ПК пользователя:
- Процессор: ${user.pcSpecs.cpu}
- Видеокарта: ${user.pcSpecs.gpu}
- Оперативная память: ${user.pcSpecs.ram}

Доступные игры: ${availableGames}

Предпочтения пользователя: ${preferences || "любые жанры"}

Порекомендуй 5 игр ИЗ СПИСКА ДОСТУПНЫХ, которые:
1. Точно запустятся на этом ПК
2. Соответствуют предпочтениям пользователя
3. Популярны в 2024-2025 году

Ответь в формате JSON:
{
  "games": [
    {
      "title": "Название игры ИЗ СПИСКА",
      "genre": "Жанр",
      "reason": "Почему подходит (1 предложение)",
      "performance": "high/medium/low"
    }
  ]
}`;

    const aiResponse = await geminiChat({
      systemInstruction: "Ты - эксперт по видеоиграм и железу ПК. Отвечай только в формате JSON.",
      history: [{ role: "user", content: prompt }],
      temperature: 0.7,
      maxOutputTokens: 500,
    });
    
    let recommendations;
    try {
      recommendations = JSON.parse(aiResponse);
    } catch (e) {
      recommendations = {
        games: [
          { title: "Counter-Strike 2", genre: "Шутер", reason: "Классический тактический шутер", performance: "high" },
          { title: "Minecraft", genre: "Песочница", reason: "Идеально для креатива", performance: "high" },
          { title: "Valorant", genre: "Шутер", reason: "Современный командный шутер", performance: "medium" },
        ],
      };
    }

    res.json({
      success: true,
      recommendations: recommendations.games,
      userPC: user.pcSpecs,
    });
  } catch (err) {
    console.error("Ошибка ИИ-рекомендаций:", err);
    
    res.json({
      success: true,
      recommendations: [
        { title: "Counter-Strike 2", genre: "Шутер", reason: "Отличная оптимизация", performance: "high" },
        { title: "Fortnite", genre: "Battle Royale", reason: "Популярная королевская битва", performance: "medium" },
        { title: "Minecraft", genre: "Песочница", reason: "Подходит для любого ПК", performance: "high" },
        { title: "Valorant", genre: "Шутер", reason: "Тактический командный шутер", performance: "medium" },
      ],
      fallback: true,
    });
  }
});

app.post("/ai-generate-game-character", authenticateToken, async (req, res) => {
  const { email, gameTitle, characterType } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Пользователь не найден",
      });
    }

    const prompt = `Создай уникального персонажа для игры ${gameTitle}.
    
Тип персонажа: ${characterType || "герой"}

Опиши персонажа (3-4 предложения):
- Внешность и стиль
- Способности и навыки
- Предыстория
- Роль в игре

Ответь креативно и интересно!`;

    const characterDescription = await geminiChat({
      systemInstruction: "Ты - креативный game designer. Создавай интересных игровых персонажей.",
      history: [{ role: "user", content: prompt }],
      temperature: 0.7,
      maxOutputTokens: 1500,
    });
    
    res.json({
      success: true,
      character: {
        game: gameTitle,
        type: characterType || "герой",
        description: characterDescription,
      },
    });
  } catch (err) {
    console.error("Ошибка генерации персонажа:", err);
    res.json({
      success: true,
      character: {
        game: gameTitle,
        type: characterType || "герой",
        description: `Представь себе сильного воина с уникальными способностями для игры ${gameTitle}. Этот герой обладает невероятной силой и может помочь команде достичь победы!`,
      },
      fallback: true,
    });
  }
});

app.post("/ai-smart-upgrade-recommendations", authenticateToken, async (req, res) => {
  const { email, gameTitle, budget = 500, targetFPS = 60 } = req.body;

  try {
    console.log("AI-Smart-Recommendations запрос:", { email, gameTitle, budget, targetFPS });

    const user = await User.findOne({ email });
    if (!user || !user.pcSpecs || !user.pcSpecs.cpu) {
      return res.status(400).json({
        success: false,
        message: "Добавьте характеристики ПК",
      });
    }

    const gameRequirements = gamesDatabase[gameTitle];
    if (!gameRequirements) {
      return res.status(400).json({
        success: false,
        message: "Игра не найдена",
      });
    }

    let currentFPS = 0;
    let compatibility = null;

    try {
      currentFPS = calculateRealFPS(user.pcSpecs, gameTitle);
      compatibility = checkCompatibility(user.pcSpecs, gameRequirements, gameTitle);
    } catch (calcErr) {
      console.error("Ошибка расчета FPS:", calcErr);
      currentFPS = 30;
    }

    const prompt = `Ты - эксперт по компьютерному железу с глубокими знаниями о производительности и совместимости компонентов.

ТЕКУЩАЯ СИСТЕМА ПОЛЬЗОВАТЕЛЯ:
- CPU: ${user.pcSpecs.cpu}
- GPU: ${user.pcSpecs.gpu}
- RAM: ${user.pcSpecs.ram}
- Хранилище: ${user.pcSpecs.storage}
- ОС: ${user.pcSpecs.os}

ИГРА: ${gameTitle}
ТЕКУЩИЙ FPS: ${currentFPS}
ЦЕЛЕВОЙ FPS: ${targetFPS}
БЮДЖЕТ: $${budget}

ЗАДАЧИ:
1. Проведи ДЕТАЛЬНЫЙ анализ текущей системы
2. Определи УЗКИЕ МЕСТА (bottleneck) - какой компонент ограничивает производительность
3. Объясни, как КАЖДЫЙ компонент влияет на FPS в этой игре
4. Найди РЕАЛЬНЫЕ актуальные компоненты 2024-2025 года для апгрейда
5. Подбери компоненты с учетом бюджета и целевого FPS

Верни ответ в формате JSON:
{
  "analysis": {
    "bottleneck": "Название компонента, который больше всего ограничивает",
    "bottleneckReason": "Почему этот компонент узкое место (2-3 предложения)",
    "cpuImpact": "Как CPU влияет на FPS в этой игре (1-2 предложения)",
    "gpuImpact": "Как GPU влияет на FPS в этой игре (1-2 предложения)",
    "ramImpact": "Как RAM влияет на FPS в этой игре (1-2 предложения)",
    "overallAssessment": "Общая оценка системы для этой игры (2-3 предложения)"
  },
  "recommendations": [
    {
      "component": "CPU/GPU/RAM",
      "name": "Точное название модели (например: AMD Ryzen 7 7800X3D)",
      "currentComponent": "Текущий компонент",
      "price": число (примерная цена в USD),
      "reason": "Почему именно этот компонент, как улучшит FPS (2-3 предложения)",
      "fpsGain": "Примерный прирост FPS (например: +30-40 FPS)",
      "priority": "high/medium/low",
      "link": "https://www.amazon.com/s?k=название (Amazon поисковая ссылка)"
    }
  ],
  "expectedFPS": число (ожидаемый FPS после всех апгрейдов),
  "totalCost": число (общая стоимость всех рекомендаций)
}echo "# flutter_gamepulse" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/Stuussy/flutter_gamepulse.git
git push -u origin main

ВАЖНО:
- Ищи ТОЛЬКО актуальные модели 2024-2025 года
- Укажи РЕАЛЬНЫЕ примерные цены на основе текущего рынка
- Учитывай бюджет пользователя
- Формируй поисковые ссылки на Amazon для каждого компонента
- Будь конкретным в названиях моделей
- Объясняй технические детали простым языком`;

    const responseText = await geminiChat({
      systemInstruction: "Ты - эксперт по компьютерному железу. Отвечай ТОЛЬКО в формате JSON. Будь точным и конкретным.",
      history: [{ role: "user", content: prompt }],
      temperature: 0.7,
      maxOutputTokens: 1000,
    });

    let aiResponse;
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : null;
    } catch (e) {
      console.error("Ошибка парсинга AI ответа:", e);
      aiResponse = null;
    }

    if (!aiResponse || !aiResponse.analysis || !aiResponse.recommendations) {
      const smartRecommendations = [];
      let totalCost = 0;

      const cpuPerf = getComponentPerformance(user.pcSpecs.cpu, 'cpu');
      const gpuPerf = getComponentPerformance(user.pcSpecs.gpu, 'gpu');
      const ramValue = parseInt(user.pcSpecs.ram);

      let bottleneck = "GPU";
      if (cpuPerf < gpuPerf * 0.7) bottleneck = "CPU";
      if (ramValue < 16) bottleneck = "RAM";

      if (gpuPerf < 250 && budget >= 400) {
        const gpuOptions = [
          { name: "NVIDIA RTX 4060 Ti 8GB", price: 450, fps: "+40-50 FPS", link: "https://www.amazon.com/s?k=RTX+4060+Ti" },
          { name: "AMD Radeon RX 7700 XT", price: 420, fps: "+35-45 FPS", link: "https://www.amazon.com/s?k=RX+7700+XT" },
        ];
        const gpu = gpuOptions[0];
        smartRecommendations.push({
          component: "GPU",
          name: gpu.name,
          currentComponent: user.pcSpecs.gpu,
          price: gpu.price,
          reason: `${gpu.name} - отличная видеокарта 2024 года для ${gameTitle}. Она обеспечит стабильные ${targetFPS}+ FPS на высоких настройках с поддержкой современных технологий.`,
          fpsGain: gpu.fps,
          priority: bottleneck === "GPU" ? "high" : "medium",
          link: gpu.link
        });
        totalCost += gpu.price;
      }

      if (cpuPerf < 200 && budget >= 250) {
        const cpuOptions = [
          { name: "AMD Ryzen 7 7800X3D", price: 380, fps: "+25-35 FPS", link: "https://www.amazon.com/s?k=Ryzen+7+7800X3D" },
          { name: "Intel Core i7-14700K", price: 400, fps: "+30-40 FPS", link: "https://www.amazon.com/s?k=i7-14700K" },
        ];
        const cpu = cpuOptions[0];
        smartRecommendations.push({
          component: "CPU",
          name: cpu.name,
          currentComponent: user.pcSpecs.cpu,
          price: cpu.price,
          reason: `${cpu.name} - топовый игровой процессор 2024 года с 3D V-Cache технологией. Идеален для ${gameTitle} благодаря большому кэшу, который критично важен для игр.`,
          fpsGain: cpu.fps,
          priority: bottleneck === "CPU" ? "high" : "medium",
          link: cpu.link
        });
        totalCost += cpu.price;
      }

      if (ramValue < 32 && budget >= 80) {
        smartRecommendations.push({
          component: "RAM",
          name: "32GB DDR4 3200MHz (2x16GB)",
          currentComponent: user.pcSpecs.ram,
          price: 85,
          reason: "32GB RAM обеспечит плавную работу игры без просадок FPS при загрузке текстур и уровней. Современные игры активно используют 16GB+.",
          fpsGain: "+10-15 FPS",
          priority: ramValue < 16 ? "high" : "low",
          link: "https://www.amazon.com/s?k=32GB+DDR4+3200MHz"
        });
        totalCost += 85;
      }

      aiResponse = {
        analysis: {
          bottleneck: bottleneck,
          bottleneckReason: bottleneck === "GPU"
            ? `Ваша видеокарта ${user.pcSpecs.gpu} является главным ограничением. В ${gameTitle} GPU отвечает за рендеринг графики, и текущая карта не справляется с современными настройками.`
            : bottleneck === "CPU"
            ? `Ваш процессор ${user.pcSpecs.cpu} ограничивает производительность. ${gameTitle} требует мощный CPU для обработки физики, AI и игровой логики.`
            : `Объем RAM ${user.pcSpecs.ram} недостаточен. Современные игры активно используют оперативную память для кэширования текстур и данных.`,
          cpuImpact: `CPU в ${gameTitle} обрабатывает игровую логику, физику и AI. Слабый процессор создает просадки FPS в динамичных сценах.`,
          gpuImpact: `GPU отвечает за рендеринг графики в ${gameTitle}. Чем мощнее видеокарта, тем выше настройки графики и стабильнее FPS.`,
          ramImpact: `RAM хранит загруженные текстуры и данные игры. Недостаток памяти вызывает подгрузки (stuttering) и снижает FPS.`,
          overallAssessment: `Ваша система способна запустить ${gameTitle}, но для комфортной игры на ${targetFPS}+ FPS требуется апгрейд. Главное узкое место - ${bottleneck}.`
        },
        recommendations: smartRecommendations,
        expectedFPS: currentFPS + 50,
        totalCost: totalCost
      };
    }

    res.json({
      success: true,
      currentFPS: currentFPS,
      targetFPS: targetFPS,
      budget: budget,
      ...aiResponse
    });

  } catch (err) {
    console.error("Ошибка AI-рекомендаций:", err);
    console.error("Stack trace:", err.stack);

    res.json({
      success: true,
      currentFPS: 30,
      targetFPS: targetFPS || 60,
      budget: budget || 500,
      analysis: {
        bottleneck: "Не определено",
        bottleneckReason: "Не удалось провести полный анализ, но система работает.",
        cpuImpact: "CPU обрабатывает игровую логику и влияет на FPS.",
        gpuImpact: "GPU отвечает за графику и рендеринг.",
        ramImpact: "RAM влияет на загрузку текстур и плавность.",
        overallAssessment: "Рекомендуем обновить компоненты для лучшей производительности."
      },
      recommendations: [],
      expectedFPS: 60,
      totalCost: 0
    });
  }
});

// ==================== PUBLIC GAMES LIST ====================

app.get("/games", (req, res) => {
  const games = Object.keys(gamesDatabase).map((title) => ({ title }));
  res.json({ success: true, games });
});

// ==================== ADMIN ENDPOINTS ====================

app.post("/admin/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.json({ success: false, message: "Неверный email или пароль" });
    }
    const isValid = await bcrypt.compare(password, admin.password);
    if (!isValid) {
      return res.json({ success: false, message: "Неверный email или пароль" });
    }
    const token = jwt.sign(
      { email: admin.email, name: admin.name, isAdmin: true },
      ADMIN_JWT_SECRET,
      { expiresIn: "7d" }
    );
    res.json({ success: true, message: "Успешный вход", token, admin: { email: admin.email, name: admin.name } });
  } catch (err) {
    console.error("Ошибка входа админа:", err);
    res.json({ success: false, message: "Ошибка сервера" });
  }
});

app.get("/admin/games", adminAuth, (req, res) => {
  const games = Object.entries(gamesDatabase).map(([title, data]) => ({
    title,
    minimum: data.minimum,
    recommended: data.recommended,
    high: data.high,
  }));
  res.json({ success: true, games });
});

app.get("/admin/components", adminAuth, (req, res) => {
  const components = {};
  for (const [type, items] of Object.entries(componentPrices)) {
    components[type] = Object.entries(items).map(([name, data]) => ({
      name,
      price: data.price,
      link: data.link,
      performance: data.performance,
      budget: data.budget,
    }));
  }
  res.json({ success: true, components });
});

app.post("/admin/add-game", adminAuth, async (req, res) => {
  const { title, minimum, recommended, high } = req.body;
  if (!title || !minimum || !recommended || !high) {
    return res.status(400).json({ success: false, message: "Заполните все поля" });
  }
  try {
    gamesDatabase[title] = { minimum, recommended, high };
    await CustomGame.findOneAndUpdate(
      { title },
      { title, minimum, recommended, high },
      { upsert: true, new: true }
    );
    res.json({ success: true, message: `Игра "${title}" добавлена` });
  } catch (err) {
    console.error("Ошибка добавления игры:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/admin/add-component", adminAuth, async (req, res) => {
  const { type, name, price, link, performance, budget } = req.body;
  if (!type || !name || !price) {
    return res.status(400).json({ success: false, message: "Заполните обязательные поля" });
  }
  try {
    if (!componentPrices[type]) componentPrices[type] = {};
    componentPrices[type][name] = { price, link: link || "", performance: performance || 100, budget: budget || "medium" };
    await CustomComponent.findOneAndUpdate(
      { type, name },
      { type, name, price, link: link || "", performance: performance || 100, budget: budget || "medium" },
      { upsert: true, new: true }
    );
    res.json({ success: true, message: `Компонент "${name}" добавлен` });
  } catch (err) {
    console.error("Ошибка добавления компонента:", err);
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.delete("/admin/delete-game", adminAuth, async (req, res) => {
  const { title } = req.body;
  try {
    delete gamesDatabase[title];
    await CustomGame.findOneAndDelete({ title });
    res.json({ success: true, message: `Игра "${title}" удалена` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.delete("/admin/delete-component", adminAuth, async (req, res) => {
  const { type, name } = req.body;
  try {
    if (componentPrices[type]) delete componentPrices[type][name];
    await CustomComponent.findOneAndDelete({ type, name });
    res.json({ success: true, message: `Компонент "${name}" удалён` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

app.post("/admin/ai-chat", adminAuth, async (req, res) => {
  const { question, messages = [] } = req.body;
  try {
    const chatHistory = [];
    if (Array.isArray(messages)) {
      for (const msg of messages) {
        if (msg && msg.text) {
          chatHistory.push({
            role: msg.isUser ? "user" : "assistant",
            content: String(msg.text),
          });
        }
      }
    }
    chatHistory.push({ role: "user", content: String(question || "Привет") });

    const response = await geminiChat({
      systemInstruction: "Ты - ИИ помощник GamePulse для администратора. Помогай с вопросами о компьютерном железе, играх, ценах, рекомендациях. Отвечай кратко и профессионально на русском языке.",
      history: chatHistory,
      temperature: 0.7,
      maxOutputTokens: 1000,
    });

    res.json({ success: true, response });
  } catch (err) {
    console.error("Admin AI chat error:", err);
    res.status(500).json({ success: false, message: "Ошибка AI сервиса" });
  }
});

// ── admin: edit game ──────────────────────────────────────────────────────────
app.put("/admin/edit-game", adminAuth, async (req, res) => {
  const { oldTitle, title, minimum, recommended, high } = req.body;
  if (!title || !minimum || !recommended || !high) {
    return res.status(400).json({ success: false, message: "Заполните все поля" });
  }
  try {
    const key = oldTitle || title;
    if (oldTitle && oldTitle !== title) delete gamesDatabase[oldTitle];
    gamesDatabase[title] = { minimum, recommended, high };
    await CustomGame.findOneAndUpdate(
      { title: key },
      { title, minimum, recommended, high },
      { upsert: true, new: true }
    );
    if (oldTitle && oldTitle !== title) await CustomGame.findOneAndDelete({ title: oldTitle });
    res.json({ success: true, message: "Игра обновлена" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: edit component ─────────────────────────────────────────────────────
app.put("/admin/edit-component", adminAuth, async (req, res) => {
  const { type, oldName, name, price, link, performance, budget } = req.body;
  if (!type || !name || price == null) {
    return res.status(400).json({ success: false, message: "Заполните обязательные поля" });
  }
  try {
    if (!componentPrices[type]) componentPrices[type] = {};
    if (oldName && oldName !== name) delete componentPrices[type][oldName];
    componentPrices[type][name] = { price, link: link || "", performance: performance || 100, budget: budget || "medium" };
    await CustomComponent.findOneAndUpdate(
      { type, name: oldName || name },
      { type, name, price, link: link || "", performance: performance || 100, budget: budget || "medium" },
      { upsert: true, new: true }
    );
    if (oldName && oldName !== name) await CustomComponent.findOneAndDelete({ type, name: oldName });
    res.json({ success: true, message: "Компонент обновлён" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: bulk delete games ──────────────────────────────────────────────────
app.delete("/admin/bulk-delete-games", adminAuth, async (req, res) => {
  const { titles } = req.body;
  if (!Array.isArray(titles)) return res.status(400).json({ success: false, message: "Передайте массив titles" });
  try {
    for (const title of titles) {
      delete gamesDatabase[title];
      await CustomGame.findOneAndDelete({ title });
    }
    res.json({ success: true, message: `Удалено ${titles.length} игр` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: bulk delete components ─────────────────────────────────────────────
app.delete("/admin/bulk-delete-components", adminAuth, async (req, res) => {
  const { components } = req.body; // [{type, name}]
  if (!Array.isArray(components)) return res.status(400).json({ success: false, message: "Передайте массив components" });
  try {
    for (const { type, name } of components) {
      if (componentPrices[type]) delete componentPrices[type][name];
      await CustomComponent.findOneAndDelete({ type, name });
    }
    res.json({ success: true, message: `Удалено ${components.length} компонентов` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: get all users ──────────────────────────────────────────────────────
app.get("/admin/users", adminAuth, async (req, res) => {
  try {
    const users = await User.find({}, "-password").sort({ createdAt: -1 });
    res.json({ success: true, users });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: delete user ────────────────────────────────────────────────────────
app.delete("/admin/delete-user", adminAuth, async (req, res) => {
  const { email } = req.body;
  try {
    await User.findOneAndDelete({ email });
    res.json({ success: true, message: `Пользователь ${email} удалён` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: block/unblock user ─────────────────────────────────────────────────
app.post("/admin/block-user", adminAuth, async (req, res) => {
  const { email, block } = req.body;
  try {
    await User.findOneAndUpdate({ email }, { isBlocked: !!block });
    res.json({ success: true, message: block ? `${email} заблокирован` : `${email} разблокирован` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

// ── admin: statistics ─────────────────────────────────────────────────────────
app.get("/admin/stats", adminAuth, async (req, res) => {
  try {
    const userCount = await User.countDocuments();
    const blockedCount = await User.countDocuments({ isBlocked: true });
    const gameCount = Object.keys(gamesDatabase).length;
    const componentCount = Object.values(componentPrices).reduce(
      (s, v) => s + Object.keys(v).length, 0
    );
    const allUsers = await User.find({}, "checkHistory");
    const gameCounts = {};
    for (const user of allUsers) {
      for (const h of user.checkHistory || []) {
        if (h.game) gameCounts[h.game] = (gameCounts[h.game] || 0) + 1;
      }
    }
    const popularGames = Object.entries(gameCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([game, count]) => ({ game, count }));
    const totalChecks = Object.values(gameCounts).reduce((s, v) => s + v, 0);
    res.json({
      success: true,
      stats: { userCount, blockedCount, gameCount, componentCount, popularGames, totalChecks },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка сервера" });
  }
});

const PORT = 3001;
app.listen(PORT, () => console.log(`🚀 Сервер запущен на порту ${PORT}`));