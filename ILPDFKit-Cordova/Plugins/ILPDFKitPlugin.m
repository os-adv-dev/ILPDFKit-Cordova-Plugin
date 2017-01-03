//
//  ILPDFKitPlugin.m
//  ILPDFKitPlugin-Cordova
//
//  Created by Yauhen Hatsukou on 22.10.14.
//
//

#import "ILPDFKitPlugin.h"
#import "ILPDFFormContainer.h"

@interface ILPDFKitPlugin ()

@property (nonatomic, strong) ILPDFViewController *pdfViewController;
@property (nonatomic, strong) NSString *fileNameToSave;
@property (nonatomic, assign) BOOL autoSave;
@property (nonatomic, assign) BOOL isAnyFormChanged;
@property (nonatomic, assign) BOOL askToSaveBeforeClose;
@property (nonatomic, assign) BOOL backgroundMode;
@property (nonatomic, assign) BOOL isKeyboardOpen;
@property (nonatomic, strong) UIButton *buttonS;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *topView;
@property CDVInvokedUrlCommand *commandT;
@property CDVPluginResult *pluginResult;
@property BOOL isPDFOpen;

@end

@implementation ILPDFKitPlugin

- (void)present:(CDVInvokedUrlCommand *)command {
    if(!_isPDFOpen){
    _isPDFOpen = true;
    _pluginResult = nil;
    _commandT = command;
    [self.commandDelegate runInBackground:^{
        NSString *pdf = [command.arguments objectAtIndex:0];
        NSDictionary *options = [command.arguments objectAtIndex:1];
        //[_pluginResult setKeepCallbackAsBool:true];
        BOOL useDocumentsFolder = [options[@"useDocumentsFolder"] boolValue];
        BOOL openFromUrl = [options[@"openFromUrl"] boolValue];
        BOOL openFromPath = [options[@"openFromPath"] boolValue];

        // verify if the document is in documents folder
        if (useDocumentsFolder) {
            pdf = [[self documentsDirectory] stringByAppendingPathComponent:pdf];
        }
        else {
            if(openFromPath){
                pdf = [self pdfFilePathWithPath:pdf];
            }
        }
        self.fileNameToSave = options[@"fileNameToSave"];
        if (self.fileNameToSave.length == 0) {
           self.fileNameToSave = [pdf lastPathComponent];
        }
        
        self.autoSave = [options[@"autoSave"] boolValue];

        self.askToSaveBeforeClose = [options[@"askToSaveBeforeClose"] boolValue];
        
        self.isAnyFormChanged = NO;

        self.backgroundMode = [options[@"backgroundMode"] boolValue];

        if (pdf && pdf.length != 0) {
            @try {
                if(openFromUrl){
                    NSURL *fileURL = [NSURL URLWithString:pdf];
                    NSURLSession *session = [NSURLSession sharedSession];
                    [[session dataTaskWithURL:fileURL completionHandler:^(NSData *data,
                                                                      NSURLResponse *response,
                                                                      NSError *error){
                        if(!error)
                        {
                            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[response suggestedFilename]];
                            [data writeToFile:filePath atomically:YES];
                            [self openPdfFromPath:filePath];
                        }
                        else{
                            NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:6], @"errorCode", @"Failed to download pdf", @"errorMessage", nil];
                            //_pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to download pdf"];
                            _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
                        }
                    
                    }] resume];
                }
                else if (openFromPath){
                    [self openPdfFromPath:pdf];
                }
                else{
                    NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:5], @"errorCode", @"One of Types of path should be choose", @"errorMessage", nil];
                    //_pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"One of Types of path should be choose"];
                    _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];

                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
                NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:3], @"errorCode", @"Failed to open pdf", @"errorMessage", nil];
                //_pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to open pdf"];
                _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
            }
        }
        else {
            NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:4], @"errorCode", @"The path/url is empty", @"errorMessage", nil];
            _pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
        }
        if(_pluginResult != nil){
            [self.commandDelegate sendPluginResult:_pluginResult callbackId:command.callbackId];
        }
    }];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ILPDFKitFormValueChangedNotitfication" object:nil];
}

- (void)onClose:(id)sender {
    if (self.askToSaveBeforeClose) {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@""
                                      message:@"You have made changes to the form that have not been saved. Do you really want to quit?"
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"YES"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [self.pdfViewController dismissViewControllerAnimated:YES completion:nil];
                                 NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"errorCode", @"Success to close pdf", @"errorMessage", nil];
                                 _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
                                 [self.commandDelegate sendPluginResult:_pluginResult callbackId:_commandT.callbackId];
                                 _isPDFOpen=false;
                             }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"NO"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:1], @"errorCode", @"The user cancel th operation", @"errorMessage", nil];
                                     _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
                                     [self.commandDelegate sendPluginResult:_pluginResult callbackId:_commandT.callbackId];
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
        
        [alert addAction:cancel];
        [alert addAction:ok];
        
        [self.pdfViewController presentViewController:alert animated:YES completion:nil];
    }
    else {
        NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"errorCode", @"Success to close pdf", @"errorMessage", nil];
        _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
        //_pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Success to close pdf"];
        
        [self.commandDelegate sendPluginResult:_pluginResult callbackId:_commandT.callbackId];
        [self.pdfViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)save:(CDVInvokedUrlCommand *)command {
    [self onSave:nil];
    self.isAnyFormChanged = NO;
}

- (void)onSave:(id)sender {
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    [_pluginResult setKeepCallbackAsBool:false];
    NSString *finalPath=[documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"%@", _fileNameToSave]];
    NSData *data = [self.pdfViewController.document savedStaticPDFData];
    NSError *error;
    [data writeToFile:finalPath options:NSDataWritingAtomic error:&error];
    
    if(error){
        NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:2], @"errorCode", @"Failed to save pdf", @"errorMessage", nil];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result]
                                    callbackId:_commandT.callbackId];
        //[self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to save pdf"]
        //                            callbackId:_commandT.callbackId];
    }else{
        NSMutableDictionary* resObj = [NSMutableDictionary dictionaryWithCapacity:1];
        [resObj setObject:finalPath forKey:@"filePath"];
        [resObj setObject:[NSNumber numberWithInteger:0] forKey:@"errorCode"];
        _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resObj];
    }
    [self.commandDelegate sendPluginResult:_pluginResult
                                callbackId:_commandT.callbackId];
    [self.pdfViewController dismissViewControllerAnimated:YES completion:nil];
    _isPDFOpen = false;

}

- (NSString *)pdfFilePathWithPath:(NSString *)path {
    if (path) {
        path = [path stringByExpandingTildeInPath];
        if (![path isAbsolutePath]) {
            path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"] stringByAppendingPathComponent:path];
        }
        return path;
    }
    return nil;
}

- (BOOL)sendEventWithJSON:(id)JSON {
    if ([JSON isKindOfClass:[NSDictionary class]]) {
        JSON = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:JSON options:0 error:NULL] encoding:NSUTF8StringEncoding];
    }
    NSString *result = @"";
//   [self.webView stringByEvaluatingJavaScriptFromString:script];
    return [result length]? [result boolValue]: YES;
}

- (NSString *)documentsDirectory {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    return documentsDir;
}

- (void)setFormValue:(CDVInvokedUrlCommand *)command {
    NSString *name = [command.arguments objectAtIndex:0];
    NSString *value = [command.arguments objectAtIndex:1];
    [self setValue:value forFormName:name];
}

- (void)setValue:(id)value forFormName:(NSString *)name {
    BOOL isFormFound = NO;
    for(ILPDFForm *form in self.pdfViewController.document.forms) {
        if ([form.name isEqualToString:name]) {
            isFormFound = YES;
            form.value = value;
            self.isAnyFormChanged = YES;
            [self formValueChanged:nil];
            break;
        }
    }
    if (!isFormFound) {
        NSLog(@"Form with name '%@' not found", name);
    }
}

- (void)getFormValue:(CDVInvokedUrlCommand *)command {
    NSString *name = [command.arguments objectAtIndex:0];

    id value = [self valueForFormName:name];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value] callbackId:command.callbackId];
    //NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"errorCode", value, @"formValue", nil];
    //[self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result] callbackId:command.callbackId];
}

- (id)valueForFormName:(NSString *)name {
    for(ILPDFForm *form in self.pdfViewController.document.forms) {
        if ([form.name isEqualToString:name]) {
            return form.value;
        }
    }
    return nil;
}

- (void)getAllForms:(CDVInvokedUrlCommand *)command {
    NSMutableArray *forms = [[NSMutableArray alloc] init];
    for(ILPDFForm *form in self.pdfViewController.document.forms) {
        [forms addObject:@{@"name" : form.name, @"value" : form.value}];
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:forms] callbackId:command.callbackId];
}

- (void)formValueChanged:(NSNotification *)notification {
    self.isAnyFormChanged = YES;
    if (self.autoSave) {
        [self onSave:nil];
        self.isAnyFormChanged = NO;
    }
}


// open pdf view from a path String
-(void) openPdfFromPath:(NSString *) path{
    dispatch_sync(dispatch_get_main_queue(), ^{
        ILPDFDocument *document = [[ILPDFDocument alloc] initWithPath:path];
        self.pdfViewController = [[ILPDFViewController alloc]init];
        [self.pdfViewController setDocument: document];
        if (!self.backgroundMode) {
            [[super viewController] presentViewController:self.pdfViewController animated:YES completion:^{
                [self addTopView];
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center addObserver:self selector:@selector(changeOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
            }];
       }
    });
}

- (void)addTopView {
    _topView= [[UIView alloc]initWithFrame:CGRectMake(0,0, [[UIScreen mainScreen] bounds].size.width ,40)];
    _topView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
    [_topView setAutoresizesSubviews:true];
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    [_button addTarget:self
                action:@selector(onClose:)
      forControlEvents:UIControlEventTouchUpInside];
    [_button setTitle:@"Close View" forState:UIControlStateNormal];
    _button.frame = CGRectMake(5, 10, 160.0, 20.0);
    [_button setTitleColor:[UIColor colorWithRed:36/255.0 green:71/255.0 blue:113/255.0 alpha:1.0] forState:UIControlStateNormal];
    _buttonS = [UIButton buttonWithType:UIButtonTypeCustom];
    [_buttonS addTarget:self
                     action:@selector(save:)
           forControlEvents:UIControlEventTouchUpInside];
    [_buttonS setTitle:@"Save PDF" forState:UIControlStateNormal];
    _buttonS.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 165.0, 10, 160.0, 20.0);
    [_buttonS setTitleColor:[UIColor colorWithRed:36/255.0 green:71/255.0 blue:113/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_topView addSubview:_buttonS];
    [_topView addSubview:_button];
    [_pdfViewController.pdfView.pdfView insertSubview:_topView aboveSubview:(ILPDFView *)[self.pdfViewController pdfView]];
}

-(void)changeOrientation{
    CGRect frm = _topView.frame;
    frm.size.width =  [[UIScreen mainScreen] bounds].size.width;
    _topView.frame = frm;
    CGRect frmbS = _buttonS.frame;
    frmbS.origin.x =  [[UIScreen mainScreen] bounds].size.width - 165;
    _buttonS.frame = frmbS;
    [_pdfViewController.pdfView.pdfView insertSubview:_topView aboveSubview:(ILPDFView *)[self.pdfViewController pdfView]];
}

@end

