/**
 * Created 02/6/2020
 * Modified 02/6/2020
 * @module to replace targetname placeholder on .h files
*/

const placeholder = "TargetName-Swift.h";
const files =["ILPDFView.m","ILPDFViewController.m"];
const pluginId = "com-outsystems-ilpdfkit-cordova"


module.exports = function (ctx) {

    var fs = ctx.requireCordovaModule('fs');
    var path = ctx.requireCordovaModule('path');
    var rootdir = "";
    var config = fs.readFileSync("config.xml").toString();
    var targetName = getValueForKey(config, "name");


    function getValueForKey(config, key) {
        var value = config.match(new RegExp('<' + key + '>(.*?)</' + key + '>', "i"))
        if (value && value[1]) {
            return value[1]
        } else {
            return null
        }
    }

    function directoryExists(path) {
        try {
            return fs.statSync(path).isDirectory();
        }
        catch (e) {
            return false;
        }
    }

    function replacer (match, p1, p2, p3, offset, string){
        return [p1,targetName.replace(" ","_"),"-Swift.h",p3].join("");
    }


    if ((directoryExists("platforms/ios"))) {
        try {
            console.log("Starting Replacing placeholders!");
            var pluginDir = path.join(rootdir, "platforms/ios/" , targetName , "Plugins" , pluginId);
            for(var count = 0;count<files.length;count++){
                filePath = path.join(pluginDir,files[count]);
                var fileContent = fs.readFileSync(filePath,'utf8');
                
                var regexAll = "([\\S|\\s]*)";
                var regex = /([\S|\s]*)(placeholder)([\S|\s]*)/gms
                var regex = new RegExp(regexAll + "("+placeholder+")" + regexAll, 'gms');

                fileContent = fileContent.replace(regex,replacer);
            
                fs.writeFileSync(filePath,fileContent);
                console.log("-Replaced "+files[count]);
            }
            console.log("Finish Replacing placeholders!");
        } catch (e) {
            console.log("❌ ", e);
        }
    }
};
