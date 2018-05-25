//
//  ChatViewController.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatViewController.h"
#import "GJGCChatInputPanel.h"
#import "ChatListView.h"
#import "ChatViewModel.h"
#import "GJCFAssetsPickerViewController.h"
@interface ChatViewController ()<GJGCChatInputPanelDelegate>
// 容器
@property (nonatomic, strong) ChatListView *chatListView;
@property (nonatomic, strong) ChatViewModel *chatViewModel;
// 输入栏
@property (nonatomic, strong) GJGCChatInputPanel *inputPanel;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - private

-(void)olym_addSubviews{
    [self.view addSubview:self.chatListView];
    [self.view addSubview:self.inputPanel];
    
    WeakSelf(ws);
    [self.chatListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ws.view);
        make.left.equalTo(ws.view);
        make.right.equalTo(ws.view);
        make.bottom.mas_equalTo(ws.inputPanel.mas_top);
    }];
}

-(void)olym_bindViewModel{
    @weakify(self);
   
}

-(void)olym_layoutNavigation{
    [self setStrNavTitle:@"密聊"];
}



#pragma mark 《$ ---------------- InputItemAction ---------------- $》
- (void)chatInputPanel:(GJGCChatInputPanel *)panel didChooseMenuAction:(GJGCChatInputMenuPanelActionType)actionType {
    
    switch (actionType){
    
            
    }
    
}

#pragma mark - 输入动作变化

- (void)inputBar:(GJGCChatInputBar *)inputBar changeToAction:(GJGCChatInputBarActionType)actionType
{
    CGFloat originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta;
    
    switch (actionType) {
        case GJGCChatInputBarActionTypeRecordAudio:
        {
            if (self.inputPanel.isFullState) {
                
                [UIView animateWithDuration:0.1 animations:^{
                    
                    self.inputPanel.gjcf_top = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - originY;
                    
                    self.chatListView.tableView.gjcf_height = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - originY;
                    
                }];
                
                [self.chatListView.tableView scrollRectToVisible:CGRectMake(0, self.chatListView.tableView.contentSize.height - self.chatListView.bounds.size.height, self.chatListView.gjcf_width, self.chatListView.gjcf_height) animated:NO];
            }
        }
            break;
        case GJGCChatInputBarActionTypeChooseEmoji:
        case GJGCChatInputBarActionTypeExpandPanel:
        {
            if (!self.inputPanel.isFullState) {
                
                [UIView animateWithDuration:0.1 animations:^{
                    
                    self.inputPanel.gjcf_top = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - 216 - originY;
                    
                    self.chatListView.gjcf_height = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - 216 - originY;
                    
                }];
                
                [self.chatListView.tableView scrollRectToVisible:CGRectMake(0, self.chatListView.tableView.contentSize.height - self.chatListView.bounds.size.height, self.chatListView.gjcf_width, self.chatListView.gjcf_height) animated:NO];
                
            }
        }
            break;
            
        default:
            break;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 《$ ---------------- Setter/Getter ---------------- $》

-(ChatViewModel *)chatViewModel{
    if(!_chatViewModel){
        
        _chatViewModel = [[ChatViewModel alloc] initWithUserId:self.currentChatUserId withDomain:self.currentChatUserDomain];
    }
    return _chatViewModel;
}

- (ChatListView *)chatListView {
    
    if (!_chatListView) {
        _chatListView = [[ChatListView alloc] initWithViewModel:self.chatViewModel];
    }
    return _chatListView;
}

- (GJGCChatInputPanel *)inputPanel {
    
    if (!_inputPanel) {
        
        _inputPanel = [[GJGCChatInputPanel alloc]initWithPanelDelegate:self];
        CGFloat originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta;
        self.inputPanel.frame = (CGRect){0,GJCFSystemScreenHeight-self.inputPanel.inputBarHeight-originY,GJCFSystemScreenWidth,self.inputPanel.inputBarHeight+216};
        
        _inputPanel.delegate = self;
        
        WeakSelf(weakSelf);
        
        [_inputPanel configInputPanelKeyboardFrameChange:^(GJGCChatInputPanel *panel,CGRect keyboardBeginFrame, CGRect keyboardEndFrame, NSTimeInterval duration,BOOL isPanelReserve) {
            
            /* 不要影响其他不带输入面板的系统视图对话 */
            if (panel.hidden) {
                return ;
            }
            
            [UIView animateWithDuration:duration animations:^{
                
                weakSelf.chatListView.tableView.gjcf_height = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight - originY - keyboardEndFrame.size.height;
                
                if (keyboardEndFrame.origin.y == GJCFSystemScreenHeight) {
                    
                    if (isPanelReserve) {
                        
                        weakSelf.inputPanel.gjcf_top = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight  - originY;
                        
                        weakSelf.chatListView.tableView.gjcf_height = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight - originY;
                        
                    }else{
                        
                        weakSelf.inputPanel.gjcf_top = GJCFSystemScreenHeight - 216 - weakSelf.inputPanel.inputBarHeight - originY;
                        
                        weakSelf.chatListView.gjcf_height = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight - originY - 216;
                        
                    }
                    
                }else{
                    
                    weakSelf.inputPanel.gjcf_top = weakSelf.chatListView.tableView.gjcf_bottom;
                    
                }
                
            }];
            
            [weakSelf.chatListView.tableView scrollRectToVisible:CGRectMake(0, weakSelf.chatListView.tableView.contentSize.height - weakSelf.chatListView.bounds.size.height, weakSelf.chatListView.gjcf_width, weakSelf.chatListView.gjcf_height) animated:NO];
            
        }];
        
        [_inputPanel configInputPanelRecordStateChange:^(GJGCChatInputPanel *panel, BOOL isRecording) {
            
            if (isRecording) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
//                    [weakSelf stopPlayCurrentAudio];
                    
                    weakSelf.chatListView.userInteractionEnabled = NO;
                    
                });
                
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    weakSelf.chatListView.userInteractionEnabled = YES;
                    
                });
            }
            
        }];
        
        [_inputPanel configInputPanelInputTextViewHeightChangedBlock:^(GJGCChatInputPanel *panel, CGFloat changeDelta) {
            
            panel.gjcf_top = panel.gjcf_top - changeDelta;
            
            panel.gjcf_height = panel.gjcf_height + changeDelta;
            
            [UIView animateWithDuration:0.2 animations:^{
                
                weakSelf.chatListView.gjcf_height = weakSelf.chatListView.gjcf_height - changeDelta;
                
                [weakSelf.chatListView.tableView scrollRectToVisible:CGRectMake(0, weakSelf.chatListView.tableView.contentSize.height - weakSelf.chatListView.bounds.size.height, weakSelf.chatListView.gjcf_width, weakSelf.chatListView.gjcf_height) animated:NO];
                
            }];
            
        }];
        
        /* 动作变化 */
        [_inputPanel setActionChangeBlock:^(GJGCChatInputBar *inputBar, GJGCChatInputBarActionType toActionType) {
            [weakSelf inputBar:inputBar changeToAction:toActionType];
        }];


    }
    return _inputPanel;
}

#pragma mark - 发送文字消息

- (void)chatInputPanel:(GJGCChatInputPanel *)panel sendTextMessage:(NSString *)text{
    [self.chatViewModel sendTextMessage:text];
}


@end
