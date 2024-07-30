const express = require("express");
const cors = require("cors");
const http = require("http");
const socketIO = require("socket.io");
const cronJobs = require("./tasks/cronJobs");
require("dotenv").config();
const { placeBet, getBalance } = require('./interaction/contractInteraction');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    methods: ["GET", "POST"],
  },
});

const coinFlip = require("./games/coinFlip");
const crash = require("./games/crash");
const userRoutes = require("./routes/userRoutes");
const caseRoutes = require("./routes/caseRoutes");
const itemRoutes = require("./routes/itemRoutes");
const marketplaceRoutes = require("./routes/marketplaceRoutes")(io);
const adminRoutes = require("./routes/adminRoutes");
const gamesRoutes = require("./routes/gamesRoutes")(io);

// Middleware
app.use(cors());
app.use(express.json());

// Routes
// app.use("/auth", authRoutes);
app.use("/users", userRoutes);
app.use("/cases", caseRoutes);
app.use("/items", itemRoutes);
app.use("/marketplace", marketplaceRoutes);
app.use("/admin", adminRoutes);
app.use("/games", gamesRoutes);

// New API routes for smart contract interaction
app.post('/api/placeBet', async (req, res) => {
  const { userAddress, betAmount, choice } = req.body;
  try {
    await placeBet(userAddress, betAmount, choice);
    res.status(200).send('Bet placed successfully');
  } catch (error) {
    console.error('Error placing bet:', error);
    res.status(500).send('Error placing bet');
  }
});

app.get('/api/balance', async (req, res) => {
  const { userAddress } = req.query;
  try {
    const balance = await getBalance(userAddress);
    res.status(200).send({ balance });
  } catch (error) {
    console.error('Error getting balance:', error);
    res.status(500).send('Error getting balance');
  }
});

// Start the games
coinFlip(io);
crash(io);

// Start the cron jobs
cronJobs.startCronJobs(io);

const port = process.env.PORT || 5001;

server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

let onlineUsers = 0;

io.on("connection", (socket) => {
  onlineUsers++;
  io.emit("onlineUsers", onlineUsers);

  socket.on("joinRoom", (userId) => {
    socket.join(userId);
  });

  socket.on("disconnect", () => {
    onlineUsers--;
    io.emit("onlineUsers", onlineUsers);
  });
});
