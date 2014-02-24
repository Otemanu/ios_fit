//
//  ListTableViewCell.h
//
//  Created by Narayana on 12/11/13.
//
//

#import <UIKit/UIKit.h>
#import "PageInstance.h"

@interface ListTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *titleLabel, *introLabel;
@property int sectionNo, tagValue, tileCategory;
@property (strong, nonatomic) PageInstance *pageInstance;
@property (strong, nonatomic) NSString *isExtraAvailable;
@property (nonatomic,assign) NSInteger hasAudio,selectedPage;
@property (nonatomic, strong) IBOutlet UIImageView *aImageView, *backgroundImageView;
@end
