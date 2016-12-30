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
@property (nonatomic, assign) BOOL showSaveButton;
@property (nonatomic, assign) BOOL isKeyboardOpen;
@property (nonatomic, strong) UIButton *buttonS;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *topView;
@property CDVInvokedUrlCommand *commandT;
@property CDVPluginResult *pluginResult;

@end

@implementation ILPDFKitPlugin

- (void)present:(CDVInvokedUrlCommand *)command {
    _commandT = command;
    [self.commandDelegate runInBackground:^{
        NSString *pdf = [command.arguments objectAtIndex:0];
        NSDictionary *options = [command.arguments objectAtIndex:1];
        [_pluginResult setKeepCallbackAsBool:true];
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
        
        self.showSaveButton = [options[@"showSaveButton"] boolValue];

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
                        _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to download pdf"];
                    }
                    
                }] resume];
                }
                else if (openFromPath){
                    [self openPdfFromPath:pdf];
                }
                else{
                    _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"One of Types of path should be choose"];

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ILPDFKitFormValueChangedNotitfication" object:nil];
}

- (void)onClose:(id)sender {
    if (self.askToSaveBeforeClose) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"You have made changes to the form that have not been saved. Do you really want to quit?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
        [alert show];
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
        _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resObj];
    }
    [self.commandDelegate sendPluginResult:_pluginResult
                                callbackId:_commandT.callbackId];
    [self.pdfViewController dismissViewControllerAnimated:YES completion:nil];


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
    ILPDFDocument *document = [[ILPDFDocument alloc] initWithPath:path];
    self.pdfViewController = [[ILPDFViewController alloc]init];
    [self.pdfViewController setDocument: document];
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
    if(_showSaveButton){
        _buttonS = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonS addTarget:self
                action:@selector(save:)
           forControlEvents:UIControlEventTouchUpInside];
        [_buttonS setTitle:@"Save PDF" forState:UIControlStateNormal];
        _buttonS.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 165.0, 10, 160.0, 20.0);
        [_buttonS setTitleColor:[UIColor colorWithRed:36/255.0 green:71/255.0 blue:113/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_topView addSubview:_buttonS];
    }
    [_topView addSubview:_button];
    if (!self.backgroundMode) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[super viewController] presentViewController:self.pdfViewController animated:YES completion:^{
                [self listSubviewsOfView:_pdfViewController.pdfView];
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center addObserver:self selector:@selector(didShow) name:UIKeyboardDidShowNotification object:nil];
                [center addObserver:self selector:@selector(didHide) name:UIKeyboardDidHideNotification object:nil];
                [center addObserver:self selector:@selector(changeOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
            }];
        });
    }
}

- (void)listSubviewsOfView:(UIView *)view {
    
    // Get the subviews of the view
    NSArray *subviews = [view subviews];

    // Return if there are no subviews
    if ([subviews count] == 0) return; // COUNT CHECK LINE
    
    for (UIView *subview in subviews) {
        
        // Do what you want to do with the subview
        if ([NSStringFromClass(subview.class) isEqualToString:@"UIWebView"]) {
            //[subview removeGestureRecognizer:singleFingerTap];
            //[subview addGestureRecognizer:singleFingerTap];
            [subview insertSubview:_topView aboveSubview:(ILPDFView *)[self.pdfViewController pdfView]];
        }
        [self listSubviewsOfView:subview];

    }
}

-(void)changeOrientation{
    CGRect frm = _topView.frame;
    frm.size.width =  [[UIScreen mainScreen] bounds].size.width;
    _topView.frame = frm;
    CGRect frmbS = _buttonS.frame;
    frmbS.origin.x =  [[UIScreen mainScreen] bounds].size.width - 165;
    _buttonS.frame = frmbS;
    [_topView setNeedsDisplay];
   [self listSubviewsOfView:_pdfViewController.pdfView];

}

-(void)didShow{
    _isKeyboardOpen = true;
}
-(void)didHide{
    _isKeyboardOpen = false;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if(!_isKeyboardOpen){
        if (_topView.hidden){
            _topView.hidden = NO;
            [UIView animateWithDuration:0.1
                             animations:^{
                                 _topView.frame = CGRectMake(0, 0,[[UIScreen mainScreen] bounds].size.width ,40);
                             } completion:^(BOOL finished) {
                             }];
        }
        else{
            [UIView animateWithDuration:0.1
                             animations:^{
                                 _topView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width ,0);
                             } completion:^(BOOL finished) {
                                 _topView.hidden = YES;
                             }];
        }
    }
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.pdfViewController dismissViewControllerAnimated:YES completion:nil];
        NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"errorCode", @"Success to close pdf", @"errorMessage", nil];
        _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
        //_pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Success to close pdf"];

    }
    else{
        NSDictionary *result =[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:1], @"errorCode", @"The user cancel th operation", @"errorMessage", nil];
        _pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
        //_pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The user cancel th operation"];
    }
    [self.commandDelegate sendPluginResult:_pluginResult callbackId:_commandT.callbackId];
}
@end

