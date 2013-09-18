package Moneycat;
use v5.14;
use strict;
use warnings;
use utf8;
use Web::Query;

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
    wq("http://www.esunbank.com.tw/info/rate_spot_exchange.aspx")
        ->find("table.datatable tr.tableContent-light td")
        ->each(
            sub {
                push @table, $_->text =~ s!\s!!gr;
            }
        );

    my @out;
    for (my $i = 0; $i < @table; $i += 3) {
        my ($name, $buy, $sell) = @table[$i, $i+1, $i+2];
        my $code = $name_to_currency_code{$name};
        my $twd  = $code =~ /_CASH$/ ? "TWD_CASH" : "TWD";
        push @out, {
            from => $code || $name,
            to   => $twd,
            buy  => $buy,
            sell => $sell
        };
    }

    return \@out;
}

sub fetch_currency_exchange_rate_from_bot {
    my @table;
    wq("http://rate.bot.com.tw/Pages/Static/UIP003.zh-TW.htm")
        ->find(".entry-content table tr td.titleLeft, .entry-content table tr td.decimal")
        ->each(
            sub {
                push @table, $_->text =~ s!\s!!gr;
            }
        );

    my @out;
    for (my $i = 0; $i < @table; $i += 5) {
        my ($name, $buy_cash, $sell_cash, $buy, $sell) = @table[$i .. $i+5];
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

    return \@out
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
