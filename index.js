var fs = require('fs');
var src;

var resemble = require('node-resemble-v2');

var args = process.argv.slice(2);

var github_img1 = fs.readFileSync(args[0]);

var github_img2 = fs.readFileSync(args[1]);

resemble(github_img1).onComplete(function(data){
    console.log(data);
});

resemble(github_img1).compareTo(github_img2).onComplete(function(data){
    console.log(data);

    fs.appendFile('results.txt', JSON.stringify(data) + ', ');
    
    src = data.getImageDataUrl();
});

var base64Data = src.replace(/^data:image\/png;base64,/, "");

fs.writeFile(args[2], base64Data, 'base64', function(err) {
  console.log(err);

  if (!err) {
      console.log('success!');
  }
});

var x =0;