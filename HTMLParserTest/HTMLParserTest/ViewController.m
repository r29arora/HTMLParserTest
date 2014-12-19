//
//  ViewController.m
//  HTMLParserTest
//
//  Created by Rajul Arora on 2014-11-26.
//  Copyright (c) 2014 Rajul Arora. All rights reserved.
//

#import "ViewController.h"
#import <hpple/TFHpple.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *currentReleases;
@property (nonatomic, strong) NSMutableDictionary *schedule;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)loadView
{
    [super loadView];
    self.schedule = [[NSMutableDictionary alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self parseLatestReleases];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.tableView.frame = CGRectMake(0.0, 20.0, self.view.frame.size.width, self.view.frame.size.height - 20.0f);
}

#pragma mark - Parse HTML from horriblesubs.info

- (void)parseLatestReleases
{
    self.currentReleases = [[NSMutableArray alloc] init];
    NSURL *url = [NSURL URLWithString:@"http://horriblesubs.info/lib/latest.php"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    TFHpple *doc = [[TFHpple alloc] initWithHTMLData:data];
    NSArray *elements = [doc searchWithXPathQuery:@"//div"];
    
    for (NSInteger x = 0; x < elements.count; x ++)
    {
        TFHppleElement *currentElement = elements[x];
        NSArray *children = [currentElement children];
        TFHppleElement *child = [children firstObject];
        
        if ([child content])
        {
            // We don't want these strings in our list of titles
            if (![[child content] isEqualToString:@"1080p"] &&
                ![[child content] isEqualToString:@"720p"] &&
                ![[child content] isEqualToString:@"480p"])
            {
                // Add the content to the list
                [self.currentReleases addObject:[child content]];
            }
        }
    }
}

- (void)parseReleaseSchedule
{
    NSURL *url = [NSURL URLWithString:@"http://horriblesubs.info/release-schedule/"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    TFHpple *doc = [[TFHpple alloc] initWithHTMLData:data];
    NSArray *elements = [doc searchWithXPathQuery:@"//*[@id='post-63']/div//h2[@class='weekday'] | //*[@id='post-63']/div/div"];
    
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *currentArray = [[NSMutableArray alloc] init];
    NSString *currentWeekday = [[NSString alloc] init];
    
    for (TFHppleElement *currentElement in elements)
    {
        NSArray *currentChildArray = [currentElement children];
        // Weekday Tag
        if (currentChildArray.count == 1)
        {
            TFHppleElement *element = currentChildArray[0];
            currentWeekday = [element content];
            currentArray = [[NSMutableArray alloc] init];
            tempDict[currentWeekday] = currentArray;
        }
        // Story Title Tag
        else if (currentChildArray.count > 1)
        {
            // Get the title
            TFHppleElement *element = currentChildArray[0];
            NSString *title = [element content];
            
            // Get the time
            TFHppleElement *timeElement = currentChildArray[1];
            NSArray *timeArray = [timeElement children];
            TFHppleElement *timeElement2 = timeArray[0];
            NSString *time = [timeElement2 content];
            
            NSArray *content = @[title, time];
            [currentArray addObject:content];
        }
    }
    self.schedule = tempDict;
}


#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = self.currentReleases[indexPath.row];
    cell.textLabel.numberOfLines = 2;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://horriblesubs.info"]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentReleases.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}
@end
