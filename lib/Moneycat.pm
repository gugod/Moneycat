package Moneycat;
use v5.14;
use strict;
use warnings;
use utf8;
use Web::Query;
use LWP::UserAgent;

$Web::Query::UserAgent = LWP::UserAgent->new( agent => "Mozilla/5.0" );

my %name_to_currency_code = (
    "美元現金"   => "USD_CASH",
    "美元"       => "USD",
    "港幣現金"   => "HKD_CASH",
    "港幣"       => "HKD",
    "日圓現金"   => "JPY_CASH",
    "日圓"       => "JPY",
    "歐元現金"   => "EUR_CASH",
    "歐元"       => "EUR",
    "人民幣現金" => "YEN_CASH",
    "人民幣"     => "CNY",
    "英鎊"       => "GBP",
    "澳幣"       => "AUD",
    "加拿大幣"   => "CAD",
    "瑞士法郎"   => "CHF",
    "新加坡幣"   => "SGD",
    "泰銖"       => "THB",
    "紐西蘭幣"   => "NZD",
    "瑞典幣"     => "SEK",
    "南非幣"     => "ZAR",
    "墨西哥披索" => "MXN",
);

sub fetch_currency_exchange_rate_from_esunbank {
    my @table;

    wq("https://www.esunbank.com.tw/bank/personal/deposit/rate/forex/foreign-exchange-rates")
        ->find("table#inteTable1 tr")
        ->each(
            sub {
                my ($i, $elem) = @_;
                return if $elem->has_class("titleRow");
                my @row;
                $elem->find("td")->each(sub { push @row, $_->text =~ s!\s!!gr });
                push @table, \@row;
            }
        );

    my @out;
    for (my $i = 0; $i < @table; $i += 1) {
        my $row = $table[$i];
        my ($name, $buy, $sell, $buy_cash, $sell_cash) = @$row;
        my ($currency) = $name =~ s/\(([A-Z]{3})\)//;
        my $code = $name_to_currency_code{$name};

        if (!defined($code)) {
            warn "Unrecognized currency name: $name";
            next;
        }

        push @out, {
            from => $code,
            to   => "TWD",
            buy  => $buy,
            sell => $sell,
        };

        if ($buy_cash && $sell_cash) {
            push @out, {
                from => $code . "_CASH",
                to   => "TWD_CASH",
                buy  => $buy_cash,
                sell => $sell_cash,
            };
        }
    }
    return \@out;
}

sub fetch_currency_exchange_rate_from_bot {
    my @table;
    wq("http://rate.bot.com.tw/xrt?Lang=zh-TW")
        ->find("table.table tbody tr")
        ->each(
            sub {
                my ($i, $elem) = @_;
                my @row;
                $elem->find("td")->each(sub { push @row, $_->text =~ s!\s!!gr });
                push @table, \@row;
            }
        );

    my @out;
    for (my $i = 0; $i < @table; $i += 1) {
        my ($name, $buy_cash, $sell_cash, $buy, $sell) = @{$table[$i]};
        $name =~ s! \A.+\(([A-Z]+)\)\z!$1!x;
        if ($buy ne "-") {
            push @out, {
                from => $name,
                to   => "TWD",
                buy  => $buy,
                sell => $sell
            }
        }

        if ($buy_cash ne "-") {
            push @out, {
                from => $name . "_CASH",
                to   => "TWD_CASH",
                buy  => $buy_cash,
                sell => $sell_cash
            }
        }
    }

    return \@out;
}

sub convert_currency_exchange_rate_to_hash {
    my $rate = pop;
    my $x = {};
    for(@$rate) {
        $_->{"$_->{from}/$_->{to}"} = { buy => $_->{buy}, sell => $_->{sell} };
    }
    return $x;
}

1;
