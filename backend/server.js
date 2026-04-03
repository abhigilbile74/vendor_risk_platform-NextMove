require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const User = require("./models/User");

const app = express();

app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGO_URI).then(() => {
  console.log("MongoDB Connected");
});

app.use("/api/auth", require("./routes/auth"));

// 📡 API to fetch users
app.get('/api/users', async (req, res) => {
  try {
    const users = await User.find({}, { fullName: 1, email: 1,mobile:1, _id: 0 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(process.env.PORT, () => {
  console.log(`Server running on port ${process.env.PORT}`);
});