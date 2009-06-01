package Games::Pandemic::Map::Pandemic;

use Geo::Mercator;
use Locale::TextDomain 'Games-Pandemic';
use Moose;

extends 'Games::Pandemic::Map';


sub _raw_diseases {
    return (
        # name, main color, max nb of disease
        [ __( "Cholera"        ) , 'blue',   24, ],
        [ __( "Yellow fever"   ) , 'yellow', 24, ],
        [ __( "Bubonic plague" ) , 'black',  24, ],
        [ __( "SARS"           ) , 'red',    24, ],
    );
}

sub _raw_cities {
    return (
    # name, disease id, x, y, [connections]
    [ __( "San Francisco"    ), 0, _lat2px(-37.79,-122.46), [1, 6, 39, 46           ] ],
    [ __( "Chicago"          ), 0, _lat2px(-41.78, -87.77), [0, 6, 7, 4, 2          ] ],
    [ __( "Montreal"         ), 0, _lat2px(-45.62, -73.78), [1, 3, 5                ] ],
    [ __( "New York"         ), 0, _lat2px(-40.52, -73.87), [2, 5, 14, 17           ] ],
    [ __( "Atlanta"          ), 0, _lat2px(-33.72, -84.37), [1, 5, 8                ] ],
    [ __( "Washington"       ), 0, _lat2px(-38.85, -76.94), [2, 3, 4, 8             ] ],
    [ __( "Los Angeles"      ), 1, _lat2px(-34.17,-118.34), [0, 1, 7, 38            ] ],
    [ __( "Mexico City"      ), 1, _lat2px(-19.43, -99.09), [1, 6, 8, 9, 10         ] ],
    [ __( "Miami"            ), 1, _lat2px(-25.75, -80.19), [4, 5, 7, 9             ] ],
    [ __( "Bogota"           ), 1, _lat2px( -4.66, -74.05), [7, 8, 10, 11, 13       ] ],
    [ __( "Lima"             ), 1, _lat2px( 12.09, -77.08), [7, 9, 12               ] ],
    [ __( "Sao Paulo"        ), 1, _lat2px( 23.52, -46.67), [9, 13, 17, 26          ] ],
    [ __( "Santiago"         ), 1, _lat2px( 33.61, -70.71), [10                     ] ],
    [ __( "Buenos Aires"     ), 1, _lat2px( 34.74, -58.41), [9, 11                  ] ],
    [ __( "London"           ), 0, _lat2px(-51.50,   0.04), [3, 15, 17, 18          ] ],
    [ __( "Essen"            ), 0, _lat2px(-51.52,   7.02), [14, 16, 18, 19         ] ],
    [ __( "Saint-Petersburg" ), 0, _lat2px(-59.95,  30.35), [15, 20, 21             ] ],
    [ __( "Madrid"           ), 0, _lat2px(-40.41,  -3.77), [3, 11, 14, 18, 22      ] ],
    [ __( "Paris"            ), 0, _lat2px(-48.90,   2.32), [14, 15, 17, 19, 22     ] ],
    [ __( "Milano"           ), 0, _lat2px(-45.52,   9.19), [15, 18, 21             ] ],
    [ __( "Moscow"           ), 2, _lat2px(-55.75,  37.66), [16, 21, 23             ] ],
    [ __( "Istanbul"         ), 2, _lat2px(-41.01,  28.95), [16, 19, 20, 22, 24, 25 ] ],
    [ __( "Algiers"          ), 2, _lat2px(-36.72,   3.06), [17, 18, 21, 25         ] ],
    [ __( "Tehran"           ), 2, _lat2px(-35.68,  51.60), [20, 24, 30, 31         ] ],
    [ __( "Baghdad"          ), 2, _lat2px(-33.29,  44.66), [21, 23, 25, 31, 32     ] ],
    [ __( "Cairo"            ), 2, _lat2px(-30.08,  31.34), [21, 22, 24, 27, 32     ] ],
    [ __( "Lagos"            ), 1, _lat2px( -6.42,   3.59), [11, 27, 28             ] ],
    [ __( "Khartoum"         ), 1, _lat2px(-15.62,  32.43), [25, 26, 28, 29         ] ],
    [ __( "Kinshasa"         ), 1, _lat2px(  4.41,  15.45), [26, 27, 29             ] ],
    [ __( "Johannesburg"     ), 1, _lat2px( 26.22,  28.03), [27, 28                 ] ],
    [ __( "Delhi"            ), 2, _lat2px(-28.67,  77.22), [23, 31, 33, 34, 35     ] ],
    [ __( "Karachi"          ), 2, _lat2px(-24.88,  67.00), [23, 24, 30, 32, 33     ] ],
    [ __( "Riyadh"           ), 2, _lat2px(-24.62,  46.81), [24, 25, 31             ] ],
    [ __( "Mumbai"           ), 2, _lat2px(-19.02,  72.79), [30, 31, 35             ] ],
    [ __( "Kolkata"          ), 2, _lat2px(-22.58,  88.38), [30, 35, 36, 41         ] ],
    [ __( "Chennai"          ), 2, _lat2px(-13.25,  81.63), [30, 33, 34, 36, 37     ] ],
    [ __( "Bangkok"          ), 3, _lat2px(-13.66, 100.65), [34, 35, 37, 40, 41     ] ],
    [ __( "Jakarta"          ), 3, _lat2px(  6.14, 106.91), [35, 36, 38, 40         ] ],
    [ __( "Sydney"           ), 3, _lat2px( 34.04, 151.38), [6, 37, 39              ] ],
    [ __( "Manila"           ), 3, _lat2px(-14.65, 120.68), [0, 38, 40, 41, 42      ] ],
    [ __( "Ho Chi Minh City" ), 3, _lat2px(-10.76, 106.71), [36, 37, 39, 41         ] ],
    [ __( "Hong Kong"        ), 3, _lat2px(-22.27, 114.14), [34, 36, 39, 40, 42, 43 ] ],
    [ __( "Taipei"           ), 3, _lat2px(-24.86, 121.54), [39, 41, 43, 47         ] ],
    [ __( "Shanghai"         ), 3, _lat2px(-31.24, 121.49), [41, 42, 44, 45, 46     ] ],
    [ __( "Beijing"          ), 3, _lat2px(-40.03, 116.28), [43, 45                 ] ],
    [ __( "Seoul"            ), 3, _lat2px(-37.59, 127.11), [43, 44, 46             ] ],
    [ __( "Tokyo"            ), 3, _lat2px(-35.71, 139.82), [0, 43, 45, 47          ] ],
    [ __( "Osaka"            ), 3, _lat2px(-34.61, 135.60), [42, 46                 ], ],
    );
}

sub _raw_start_city {
    return 4; # start at atlanta
}

{
    # we have 3 reference points:
    #      lat,   long = x on map, y on map
    #     0.00,   0.00 = 461, 358
    #   -87.77, -41.78 = 164, 200 (chicago)
    #   -99.09, -19.43 = 124, 290 (mexico)
    # we're using chicago to complement the origin.
    my ($xref, $yref) = mercate(-41.78, -87.77);
    sub _lat2px {
        my ($lat, $long) = @_;
        my ($xm, $ym) = mercate($lat, $long);
        my $x = int( 461 + (164-461) / $xref * $xm );
        my $y = int( 358 + (200-358) / $yref * $ym );
        return ($x, $y);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
