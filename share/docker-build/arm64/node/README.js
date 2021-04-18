//node README.js
var country = "China";
console.log('\x1B[36m%s\x1B[0m \x1B[31m%s\x1B[0m.', "If you live in", country);
console.log("%s \x1B[32m%s\x1B[0m.","Then you can run the following", "commands");
console.log("\x1B[33m%s\n%s\n%s\n\x1B[0m", "npm config set registry https://repo.huaweicloud.com/repository/npm/", "npm config set disturl https://repo.huaweicloud.com/nodejs", "npm config set electron_mirror https://repo.huaweicloud.com/electron/");
