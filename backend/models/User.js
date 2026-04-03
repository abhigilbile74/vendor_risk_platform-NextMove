const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  fullName: String,
  mobile: String,
  email: { type: String, unique: true },
  password: String,
});

module.exports = mongoose.model("User", userSchema);