//define
#import "DEFINE.h"

//vc+delegate
#import "DetailVC.h"
#import "UserVC.h"
#import "AddBucketVC.h"

#import "AppDelegate.h"

//model
#import "SHOTS.h"
#import "IMAGES.h"
#import "COMMENTS.h"
#import "USER.h"


//view
#import "CommentsCell.h"
#import "AvatarV.h"

//frame
#import "AFNetworking.h"
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView+AFNetworking.h"
#import "MJRefresh.h"

@interface DetailVC ()<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,NSURLConnectionDelegate,UIGestureRecognizerDelegate>
{
    UIView * _bigBG;
    UIButton *_likeB;
}
@property AppDelegate * myDelegate;
@property UITableView * commentsView;
@property SHOTS *shot;
@property NSString *access_token;
@property (nonatomic)  NSFetchedResultsController * fetchedResultsController;

@end

static NSString *cellRe = @"cell";

@implementation DetailVC

#pragma mark - View
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = BG_COLOR;

    self.myDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    self.access_token = [[NSUserDefaults standardUserDefaults] objectForKey:@"access_token"];

    NSError *objectError=nil;
    
    NSManagedObject *shotsObject = [self.myDelegate.managedObjectContext existingObjectWithID:self.objectID error:&objectError];
    _shot = (SHOTS *)shotsObject;
    

    
    [self setNav];
    [self mainView];
    [self userV];
    
    self.commentsView = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.commentsView.delegate = self;
    self.commentsView.dataSource = self;
    self.commentsView.backgroundColor = BG_COLOR;
    [self.commentsView registerClass:[CommentsCell class] forCellReuseIdentifier:cellRe];
    self.commentsView.tableHeaderView = _bigBG;
    self.commentsView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.commentsView addHeaderWithTarget:self action:@selector(commentsRefresh)];
    self.view = self.commentsView;
    
    [self.commentsView performSelector:@selector(headerBeginRefreshing) withObject:self afterDelay:0.6f];
    

    
}

#pragma mark -
#pragma mark SetNav

-(void)setNav
{
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, UI_NAVIGATION_BAR_HEIGHT, UI_NAVIGATION_BAR_HEIGHT)];
    titleLabel.text = self.shot.title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    self.navigationItem.titleView = titleLabel;
    titleLabel.userInteractionEnabled = YES;
    
    UIBarButtonItem *leftBBI = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"back"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = leftBBI;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
    self.view = nil;
}

#pragma mark -
#pragma mark drawV

-(void)mainView
{
    UIView *bigBG = [[UIView alloc]init];
    bigBG.backgroundColor = BG_COLOR;
    _bigBG = bigBG;
    
    UIView *whiteBG = [[UIView alloc]initWithFrame:CGRectMake(4, 4, SCREENX-8, (SCREENX-8)*3/4+2)];
    whiteBG.backgroundColor = [UIColor whiteColor];
    whiteBG.layer.masksToBounds = YES;
    whiteBG.layer.cornerRadius = 1.5f;
    [bigBG addSubview:whiteBG];
    
    IMAGES *images = _shot.images;
    NSURL *normalUrl = [NSURL URLWithString:images.normal];


    FLAnimatedImageView *shotsV = [[FLAnimatedImageView alloc]initWithFrame:CGRectMake(4, 4, whiteBG.frame.size.width-8, (whiteBG.frame.size.width-8)*3/4)];
    shotsV.layer.masksToBounds = YES;
    shotsV.layer.cornerRadius = 2.0f;
    shotsV.userInteractionEnabled = YES;
    

    NSRange range = [images.teaser rangeOfString:@"teaser"];
    NSString *str = [images.teaser substringFromIndex:range.location+6];
    
    if ([str isEqualToString:@".gif"]) {
        
        if (images.hidpi != nil) {
            NSURL *hidpiURL = [NSURL URLWithString:images.hidpi];
            NSURLRequest *request = [NSURLRequest requestWithURL:hidpiURL];
            [shotsV setAnimatedImageWithURLRequest:request
                                  placeholderImage:[UIImage imageNamed:@"shotsPlaceHolder"]
                                           success:nil
                                           failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                           }];
            
        }
        else
        {
            NSURLRequest *request = [NSURLRequest requestWithURL:normalUrl];
            [shotsV setAnimatedImageWithURLRequest:request
                                  placeholderImage:[UIImage imageNamed:@"shotsPlaceHolder"]
                                           success:nil
                                           failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                           }];
        }

    }
    else
    {
        if (images.hidpi != nil) {
            NSURL *hidpiURL = [NSURL URLWithString:images.hidpi];
            [shotsV setImageWithURL:hidpiURL placeholderImage:[UIImage imageNamed:@"shotsPlaceHolder"]];
            
        }
        else
        {
            [shotsV setImageWithURL:normalUrl placeholderImage:[UIImage imageNamed:@"shotsPlaceHolder"]];
        }
        
    }
    
    
    
    
    
    UITapGestureRecognizer *likeGR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleLike)];
    likeGR.numberOfTapsRequired = 2;
    [shotsV addGestureRecognizer:likeGR];
    [whiteBG addSubview:shotsV];

 
    NSArray *buttonArray = @[@"detail_comment",@"detail_bucket",@"detail_like"];
    
    float sum = 40;
    for (int i = 0; i < buttonArray.count; i ++) {
        
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(sum, 10+whiteBG.frame.origin.y+whiteBG.frame.size.height, 40, 40)];
        button.tag = i;
        NSString *buttonStr_1 = buttonArray[i];
        NSString *buttonStr_2 = [buttonStr_1 stringByAppendingString:@"_1"];
        
        [button setBackgroundImage:[UIImage imageNamed:buttonStr_1] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:buttonStr_2] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        sum = sum + SCREENX/3;
        [bigBG addSubview:button];
        if (i == 2) {
            [self checkLikeAction];
            _likeB = button;
        
        }
        
    }
    
    UIView *lineV = [[UIView alloc]initWithFrame:CGRectMake(0, 60+whiteBG.frame.origin.y+whiteBG.frame.size.height - 0.7f, SCREENX, 0.7f)];
    lineV.backgroundColor = RGBA(200, 200, 200, 1);
    lineV.opaque = YES ;
    [bigBG addSubview:lineV];
    
}


-(void)userV
{
    UIFont *font = [UIFont systemFontOfSize:11];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *descriptionA = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle.copy};
    CGSize descriptionSize = [self.shot.shot_description boundingRectWithSize:CGSizeMake(SCREENX - 90, 10000) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:descriptionA context:nil].size;
    
    AvatarV *avatarV = [[AvatarV alloc]initWithFrame:CGRectMake(0, (SCREENX-8)*3/4+66 , SCREENX, descriptionSize.height+110)];
    NSURL *avatarURL = [NSURL URLWithString:self.shot.user.avatar_url];
    
    [avatarV.avatarIV setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"avatarPlaceHolder"]];
    
    [avatarV.userL setText:self.shot.user.name];
    NSRange range = [self.shot.created_at rangeOfString:@"T"];
    
    
    [avatarV.timeL setText:[self.shot.created_at substringToIndex:range.location]];
    [avatarV.descriptionL setText:self.shot.shot_description];
    
    [avatarV.commentsCountL setText:[NSString stringWithFormat:@"%@ Reponses",self.shot.comments_count  ]];
    avatarV.descriptionL.frame = CGRectMake((avatarV.avatarIV.frame.origin.x)*1.5+avatarV.avatarIV.frame.size.width, avatarV.userL.frame.size.height+avatarV.userL.frame.origin.y, descriptionSize.width, descriptionSize.height+30);
    
    
    avatarV.timeL.frame = CGRectMake(self.view.frame.size.width - 120, descriptionSize.height+70 , 100 , 20);
    avatarV.commentsCountL.frame = CGRectMake(avatarV.avatarIV.frame.origin.x, avatarV.timeL.frame.origin.y+20, SCREENX, 10);
    avatarV.lineV.frame = CGRectMake(0, avatarV.commentsCountL.frame.origin.y + avatarV.commentsCountL.frame.size.height+5, SCREENX, 0.7f);
    
    [_bigBG addSubview:avatarV];
    
    UITapGestureRecognizer *commentTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(commentTapAction)];
    [avatarV.commentsCountL addGestureRecognizer:commentTap];
    
    
    UITapGestureRecognizer *userTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(userTapAction)];
    [avatarV.avatarIV addGestureRecognizer:userTap];
    
    UITapGestureRecognizer *userLT = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(userTapAction)];
    [avatarV.userL addGestureRecognizer:userLT];

    _bigBG.frame = CGRectMake(0, 0, SCREENX, avatarV.frame.origin.y + avatarV.frame.size.height);

}

#pragma mark - 
#pragma mark  NetAction

-(void)commentsRefresh
{
    BACK((^{

        NSString *str = [[NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/comments?access_token=%@&per_page=%@",self.shotsID,self.access_token,self.shot.comments_count]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:str];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            
            NSString *lastModified = [[operation.response allHeaderFields] valueForKey:@"Last-Modified"];
            
            if ([self.shot.commentslastmodified isEqualToString:lastModified]) {
                [self.commentsView headerEndRefreshing];
                return ;
            }
            self.shot.commentslastmodified = lastModified;
            
            NSArray *array = (NSArray *)responseObject;
            NSInteger i = 0;

            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_group_t group = dispatch_group_create();
        
            [self.shot removeComments:self.shot.comments];
            
            for (NSDictionary *dic in array) {

                COMMENTS *comments = EntityObjects(@"COMMENTS");
                
                comments.i = [NSNumber numberWithInteger:i];
             
                comments.shots = self.shot;
                
                comments.likes_count = [[dic objectForKey:@"likes_count"] stringValue];
                comments.body = [dic objectForKey:@"body"];
                comments.comment_id = [[dic objectForKey:@"id"] stringValue];
                comments.updated_at = [dic objectForKey:@"updated_at"];
                
                dispatch_group_async(group, queue, ^{
                    [self checkCommentLike:comments.comment_id :comments];
                });

                USER *user = EntityObjects(@"USER");
                comments.user = user;
              
                user.avatar_url = [[dic objectForKey:@"user"]objectForKey:@"avatar_url"];
                user.name = [[dic objectForKey:@"user"] objectForKey:@"name"];
                user.userid = [[[dic objectForKey:@"user"]objectForKey:@"id"]stringValue];
                user.shots_count = [[[dic objectForKey:@"user"]objectForKey:@"shots_count"]stringValue];
                user.likes_count = [[[dic objectForKey:@"user"]objectForKey:@"likes_count"]stringValue];
                user.followers_count = [[[dic objectForKey:@"user"]objectForKey:@"followers_count"]stringValue];
                user.followings_count = [[[dic objectForKey:@"user"]objectForKey:@"followings_count"]stringValue];
                user.buckets_count = [[[dic objectForKey:@"user"]objectForKey:@"buckets_count"]stringValue];
                
                user.bio = [[dic objectForKey:@"user"]objectForKey:@"bio"];
                
                user.pro = [[[dic objectForKey:@"user"]objectForKey:@"pro"]stringValue];
                
                if ( [[[[dic objectForKey:@"user"]objectForKey:@"links"] objectForKey:@"web"] class] != [NSNull class])
                {
                    user.web = [[[dic objectForKey:@"user"]objectForKey:@"links"] objectForKey:@"web"];
                }
                if ( [[[[dic objectForKey:@"user"]objectForKey:@"links"] objectForKey:@"twitter"] class] != [NSNull class])
                {
                    user.twitter = [[[dic objectForKey:@"user"]objectForKey:@"links"] objectForKey:@"twitter"];
                }
                if ([[[dic objectForKey:@"user"] objectForKey:@"location"]class] != [NSNull class]) {
                    user.location = [[dic objectForKey:@"user"] objectForKey:@"location"];
                }

                i ++;

                [self douma_save];
        };
            MAIN(^{
                [self.commentsView headerEndRefreshing];
            });
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            MAIN(^{
                [self.commentsView headerEndRefreshing];
            });
            NSLog(@"Error:%@ ___ %@",error ,[error userInfo]);
        }];
        [operation start];
        
    }));
}

#pragma mark - 
#pragma mark ClickAction

-(void)userTapAction
{
    UserVC *userVC = [[UserVC alloc]init];
    NSManagedObjectID *userObjectID = [self.shot.user objectID];
    userVC.userID = self.shot.user.userid;
    userVC.userObjectID = userObjectID;
    [self.navigationController pushViewController:userVC animated:YES];
    
}

-(void)likeAction :(UIButton *)button
{
    BOOL shotLike = button.selected;
    if (shotLike) {
        
        [self cancelLike:button];
    }
    else
    {
        [self makeLike:button];
    }
}

-(void)doubleLike
{
    BOOL shotLike = _likeB.selected;
    
    if (!shotLike) {
        AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        NSString *bearerStr =[NSString stringWithFormat:@"Bearer %@",self.access_token];
        [manager.requestSerializer setValue:bearerStr forHTTPHeaderField:@"Authorization"];
        NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/like",self.shotsID ];
        [manager POST:str parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            _likeB.selected = YES;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            _likeB.selected = NO;
        }];

    }
    
    UIImageView *whiteLikeV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteLike"]];
    whiteLikeV.frame = _likeB.frame;
    whiteLikeV.alpha = 1.0f;
    [_bigBG addSubview:whiteLikeV];
    
    [self likeAnimationBegin:whiteLikeV];
    
}
-(void)likeAnimationBegin:(UIImageView *)whiteLike
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(likeAnimationBack)];
    whiteLike.frame = CGRectMake(SCREENX/3, SCREENX/4, SCREENX/3, SCREENX/3);
    whiteLike.alpha = 0.7;
    [UIView commitAnimations];

}
-(void)likeAnimationBack
{
    UIImageView *whiteLike = [_bigBG.subviews objectAtIndex:6];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeV)];
    whiteLike.frame = CGRectMake(SCREENX/2, SCREENX/4+SCREENX/6, 0, 0);
    whiteLike.alpha = 1.0f;
    [UIView commitAnimations];

}

-(void)removeV
{
    UIImageView *whiteLike = [_bigBG.subviews objectAtIndex:6];
    [whiteLike removeFromSuperview];
}


-(void)commentLikeAction:(UIButton *)button
{
    
    CommentsCell *cell = (CommentsCell *)button.superview;
    NSIndexPath *indexPath = [self.commentsView indexPathForCell:cell];
    COMMENTS *comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    BOOL didCommentLike = button.selected;
    if (didCommentLike) {
        [self commentCancelLike:button :comment];
    }
    else
    {
        [self commentMakeLike:button :comment];
    }
}


-(void)avatarAction:(UITapGestureRecognizer *)tap
{
    UITableViewCell *cell = (UITableViewCell *)tap.view.superview;
    NSIndexPath *indexPath = [self.commentsView indexPathForCell:cell];
    UserVC *userVC = [[UserVC alloc]init];
    COMMENTS *comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID *userObjectID = [comment.user objectID];
    userVC.userID = comment.user.userid;
    userVC.userObjectID = userObjectID;
    [self.navigationController pushViewController:userVC animated:YES];
    
}

-(void)buttonAction:(UIButton *)button
{
    switch (button.tag) {
            
        case 0:
            [self commentTapAction];
            button.selected = YES;
            break;
            
        case 1:
            [self addToBuckets:button];
            break;
            
        case 2:
            [self likeAction:button];
            break;
    }
}
#pragma mark -
#pragma mark LikeSeries

-(void)checkLikeAction
{
    BACK((^{
        
        NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/like?access_token=%@",self.shotsID,self.access_token];
        NSURL *url = [NSURL URLWithString:[str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
        operation.responseSerializer = [AFHTTPResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSLog(@"%@",[[operation.response allHeaderFields] objectForKey:@"Status"]);
            MAIN(^{
                _likeB.selected = YES;
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"%@",[[operation.response allHeaderFields] objectForKey:@"Status"]);
            
        }];
        
        [operation start];
        
    }));
}



-(void)makeLike :(UIButton *)button
{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *bearerStr =[NSString stringWithFormat:@"Bearer %@",self.access_token];
    [manager.requestSerializer setValue:bearerStr forHTTPHeaderField:@"Authorization"];
    NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/like",self.shotsID ];
    [manager POST:str parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self doubleLike];
        button.selected = YES;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        button.selected = NO;
    }];


}



-(void)cancelLike :(UIButton *)button
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *bearerStr =[NSString stringWithFormat:@"Bearer %@",self.access_token];
    [manager.requestSerializer setValue:bearerStr forHTTPHeaderField:@"Authorization"];
    NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/like",self.shotsID ];
    [manager DELETE:str parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        button.selected = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        button.selected = YES;
    }];
}

#pragma mark -
#pragma mark BucketsSeries

-(void)addToBuckets:(UIButton *)button
{
    [AddBucketVC addBucketShow:self.shot inButton:button];
    [self.commentsView scrollRectToVisible:CGRectMake(0, -64, SCREENX, SCREENY) animated:NO];
}

#pragma mark -
#pragma mark CommentSeries

-(void )checkCommentLike:(NSString *)commentID :(COMMENTS *)comment
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *bearerStr =[NSString stringWithFormat:@"Bearer %@",self.access_token];

    [manager.requestSerializer setValue:bearerStr forHTTPHeaderField:@"Authorization"];
    NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/comments/%@/like",self.shotsID,commentID];
    [manager GET:str parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        comment.didlike = @"1";
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        comment.didlike = @"0";
    }];
}


-(void)commentMakeLike :(UIButton *)button :(COMMENTS *)comment
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *bearerStr =[NSString stringWithFormat:@"Bearer %@",self.access_token];
    [manager.requestSerializer setValue:bearerStr forHTTPHeaderField:@"Authorization"];
    NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/comments/%@/like",self.shotsID,comment.comment_id];
    [manager POST:str parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        button.selected = YES;
        comment.didlike = @"1";
        [self douma_save];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        button.selected = NO;
        comment.didlike = @"0";
        [self douma_save];
        
    }];
    
    
}
-(void)commentCancelLike :(UIButton *)button :(COMMENTS *)comment
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *bearerStr =[NSString stringWithFormat:@"Bearer %@",self.access_token];

    [manager.requestSerializer setValue:bearerStr forHTTPHeaderField:@"Authorization"];
    NSString *str = [NSString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/comments/%@/like",self.shotsID,comment.comment_id];
    [manager DELETE:str parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        button.selected = NO;
        comment.didlike = @"0";
        [self douma_save];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        button.selected = YES;
        comment.didlike = @"1";
        [self douma_save];

    }];
}


-(void)commentTapAction
{
    [self.commentsView scrollRectToVisible:CGRectMake(0,_bigBG.frame.size.height-25 , self.commentsView.frame.size.width, self.commentsView.frame.size.height) animated:YES];
}
#pragma mark -
#pragma mark UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self sizeOfCell:indexPath].height + 70;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

-(NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

#pragma mark UITableViewDataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentsCell *cell = [[CommentsCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellRe];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(CommentsCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    
    COMMENTS *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    CGSize commentSize = [self sizeOfCell:indexPath];
    
    cell.commentL.frame = CGRectMake((cell.avatarIV.frame.origin.x)*1.5 + cell.avatarIV.frame.size.width, cell.userL.frame.size.height+cell.userL.frame.origin.y, commentSize.width, commentSize.height+20);
    cell.timeL.frame = CGRectMake(self.view.frame.size.width - 120, commentSize.height+40 , 100 , 20);
    cell.lineV.frame = CGRectMake(cell.userL.frame.origin.x, commentSize.height+69, self.view.frame.size.width, 0.7f);
    NSURL *avatarURL = [NSURL URLWithString:object.user.avatar_url];
    [cell.avatarIV setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"avatarPlaceHolder"]];
    UITapGestureRecognizer *avatarTap = (UITapGestureRecognizer *)[cell.avatarIV.gestureRecognizers objectAtIndex:0];
    [avatarTap addTarget:self action:@selector(avatarAction:)];
        
    UITapGestureRecognizer *userTap = (UITapGestureRecognizer *)[cell.userL.gestureRecognizers objectAtIndex:0];
    [userTap addTarget:self action:@selector(avatarAction:)];
    NSRange range = [object.updated_at rangeOfString:@"T"];

    
    [cell.userL setText:object.user.name];
    [cell.commentL setText:object.body];
    [cell.likesL setText:object.likes_count];
    [cell.timeL setText:[object.updated_at substringToIndex:range.location]];
    [cell.likeB addTarget:self  action:@selector(commentLikeAction:) forControlEvents:UIControlEventTouchUpInside];
    if ([object.didlike isEqualToString:@"1"]) {
        cell.likeB.selected = YES;
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"COMMENTS" inManagedObjectContext:self.myDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];

    //关系
    NSPredicate * cdt = [NSPredicate predicateWithFormat:@"shots = %@",self.shot];
    [fetchRequest setPredicate:cdt];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"i" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.myDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.commentsView beginUpdates];

}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
        switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.commentsView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.commentsView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }

}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.commentsView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.commentsView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            CommentsCell *cell = (CommentsCell *)[self.commentsView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell atIndexPath:indexPath];
        }
            break;
            
        case NSFetchedResultsChangeMove:
            [self.commentsView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.commentsView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }


}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
 
    [self.commentsView endUpdates];
 

}

-(void)deleteEntityObject: (NSString *)enityName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:enityName inManagedObjectContext:self.myDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.myDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        [self.myDelegate.managedObjectContext deleteObject:object];
    }
    [self douma_save];
}

-(void)douma_save
{
    NSError *error = nil;
    if (![self.myDelegate.managedObjectContext save:&error])
    {
        NSLog(@"Error%@:%@",error,[error userInfo]);
    }
    
}
#pragma mark -
#pragma mark Other

-(CGSize)sizeOfCell:(NSIndexPath *)indexPath
{
    COMMENTS *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UIFont *font = [UIFont systemFontOfSize:11];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle.copy};
    CGSize size = [object.body boundingRectWithSize:CGSizeMake(SCREENX - 100, 10000) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
    return size;
    
}




    
#pragma mark -
#pragma mark System

-(void)viewWillAppear:(BOOL)animated
{
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]){
        NSArray *list=self.navigationController.navigationBar.subviews;
        for (id obj in list) {
            if ([obj isKindOfClass:[UIImageView class]]) {
                UIImageView *imageView=(UIImageView *)obj;
                imageView.hidden=NO;
            }
        }
    }
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
    
    
@end
