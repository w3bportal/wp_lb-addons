
CREATE TABLE IF NOT EXISTS `wp_lb_addons_trendy_views` (
    `viewer_id`        VARCHAR(100) NOT NULL,
    `creator_username` VARCHAR(50)  NOT NULL,
    `collected`        TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (`viewer_id`, `creator_username`),
    INDEX `idx_pending` (`collected`, `creator_username`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wp_lb_addons_birdy_payouts` (
    `tweet_id`      VARCHAR(10) NOT NULL,
    `paid_likes`    INT         NOT NULL DEFAULT 0,
    `paid_retweets` INT         NOT NULL DEFAULT 0,
    `paid_replies`  INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (`tweet_id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
