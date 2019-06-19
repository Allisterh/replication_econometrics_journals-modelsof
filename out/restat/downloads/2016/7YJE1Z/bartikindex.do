
/*do file name: Bartickindex.do

follow Bartick (1991),construct the Bartick index for each city, each year, 
follow appendix A in Saks (2008) JUE paper

This Bartik index is used to proxy for labor demand shock, which is the predicted
change (growth) in labor demand. It is a weighted average of national industry growth 
rates, the weights are the share of an indusry's employment (relative to total 
city employment).
Three indexes are generated in this do file:

bartikindex1: weighted national industry growth, weights are industry emp share
in a city (lagged one year);

bartikindex2: weighted national industry growth, weights are industry emp share
in a city (lagged one year); national ind emp growth excludes ind emp in a city


bartikindex3: weighted relative national industry growth, weights are industry emp share
in a city (lagged one year); relative national industry growth is national industry 
growth minus national emp growth;

bartikindex4: same as bartikindex2 but the national industry emp excludes ind 
emp of a particular city in question, this is Saks' appendix formula.

There may other ways to construct this index, but only need to edit this do
file slightly

Note: employment by industry is only for "unit" (danwei) emp, excluding
private sectors. Industry classification is consistent from 2003, so the final
bartik index is only available for 2004-2011*/

set more off
use CityYearsbook_1999_2011.dta

/*w*:whole city;  c*: inner city; consistent industry classification are 
available only from 2003-2011*/

rename a1153 wtotalemp /*ȫ����ĩ��λ��ҵ��Ա��(����)*/
rename a1154 ctotalemp /*��Ͻ����ĩ��λ��ҵ��Ա��(����)*/

rename a1013  windustry1 /* ȫ�е�һ��ҵ(ũ.��.��.��ҵ)��λ��ҵ��Աͳ��(����)*/
rename a1014  cindustry1  /*��Ͻ����һ��ҵ(ũ.��.��.��ҵ)��λ��ҵ��Աͳ��(����)*/
 
rename a1015  windustry2  /* ȫ�вɿ�ҵ��λ��ҵ��Աͳ��(����)*/
rename a1016  cindustry2  /* ��Ͻ���ɿ�ҵ��λ��ҵ��Աͳ��(����)*/

rename a1017  windustry3  /*ȫ������ҵ��λ��ҵ��Աͳ��(����)*/
rename a1018  cindustry3  /* ��Ͻ������ҵ��λ��ҵ��Աͳ��(����)*/

rename a1019  windustry4  /*ȫ�е���.ȼ����ˮ�������͹�Ӧҵ��λ��ҵ��Աͳ��(����)*/
rename a1020  cindustry4  /*��Ͻ������.ȼ����ˮ�������͹�Ӧҵ��λ��ҵ��Աͳ��(��*/
                                           
rename a1021  windustry5  /* ȫ�н���ҵ��λ��ҵ��Աͳ��(����)*/
rename a1022  cindustry5  /* ��Ͻ������ҵ��λ��ҵ��Աͳ��(����)*/

rename a1023  windustry6  /* ȫ�н�ͨ����.�ִ�������ҵ��λ��ҵ��Աͳ��(����)*/
rename a1024  cindustry6   /*��Ͻ����ͨ����.�ִ�������ҵ��λ��ҵ��Աͳ��(����)*/

rename a1025  windustry7   /* ȫ����Ϣ����.�������������ҵ��λ��ҵ��Աͳ��(����)*/
rename a1026  cindustry7   /*  ��Ͻ����Ϣ����.�������������ҵ��λ��ҵ��Աͳ��(��*/

rename a1027  windustry8  /* ȫ������������ҵ��λ��ҵ��Աͳ��(����)*/
rename a1028  cindustry8  /* ��Ͻ������������ҵ��λ��ҵ��Աͳ��(����)*/

rename a1029 windustry9    /*ȫ��ס��.����ҵ��λ��ҵ��Աͳ��(����)*/
rename a1030 cindustry9    /*��Ͻ��ס��.����ҵ��λ��ҵ��Աͳ��(����)*/

rename a1031 windustry10   /*  ȫ�н���ҵ��λ��ҵ��Ա(����)*/
rename a1032 cindustry10   /*��Ͻ������ҵ��λ��ҵ��Ա(����)*/

rename a1033 windustry11    /*ȫ�з��ز�ҵ��λ��ҵ��Ա(����)*/
rename a1034 cindustry11    /* ��Ͻ�����ز�ҵ��λ��ҵ��Ա(����)*/

rename a1035 windustry12     /*ȫ�����޺���ҵ����ҵ��λ��ҵ��Ա(����)*/
rename a1036 cindustry12      /*��Ͻ�����޺���ҵ����ҵ��λ��ҵ��Ա(����)*/

rename a1037 windustry13     /* ȫ�п�ѧ�о�.��������͵��ʿ���ҵ��λ��ҵ��Ա(����)*/
rename a1038 cindustry13     /* ��Ͻ����ѧ�о�.��������͵��ʿ���ҵ��λ��ҵ��Ա(����*/

rename a1039 windustry14     /* ȫ��ˮ��.�����͹�����ʩ����ҵ��λ��ҵ��Ա(���ˣ�*/
rename a1040 cindustry14     /*��Ͻ��ˮ��.�����͹�����ʩ����ҵ��λ��ҵ��Ա(���ˣ�*/
 
rename a1041 windustry15     /* ȫ�о���������������ҵ��λ��ҵ��Ա(����)*/
rename a1042 cindustry15     /* ��Ͻ������������������ҵ��λ��ҵ��Ա(����)*/

rename a1043 windustry16     /*ȫ�н���ҵ��λ��ҵ��Ա(����)*/
rename a1044 cindustry16     /* ��Ͻ������ҵ��λ��ҵ��Ա(����)*/

rename a1045 windustry17     /* ȫ������.��ᱣ�Ϻ���ḣ��ҵ(����)*/
rename a1046 cindustry17     /* ��Ͻ������.��ᱣ�Ϻ���ḣ��ҵ(����)*/

rename a1047 windustry18    /* ȫ���Ļ�.����������ҵ(����)*/
rename a1048 cindustry18    /* ��Ͻ���Ļ�.����������ҵ(����)*/

rename a1049  windustry19   /* ȫ�й�������������֯(����)*/
rename a1050  cindustry19   /* ��Ͻ����������������֯(����)*/

/*the following classification is available only in 1999-2002*/
/*a1309           double %10.0g                 ȫ��������ҵ��ҵ��Ա�������ˣ�
a1310           double %10.0g                 ��Ͻ��������ҵ��ҵ��Ա�������ˣ�
a1311           double %10.0g                 ȫ������������ḣ��ҵ��ҵ��Ա�������ˣ�
a1312           double %10.0g                 ��Ͻ������������ḣ��ҵ��ҵ��Ա�������ˣ�
a1313           double %10.0g                 ȫ�н������չ㲥Ӱ��ҵ��ҵ��Ա�������ˣ�
a1314           double %10.0g                 ��Ͻ���������չ㲥Ӱ��ҵ��ҵ��Ա�������ˣ�
a1315           double %10.0g                 ȫ�п����ۺϼ�������ҵ��ҵ��Ա�������ˣ�
a1316           double %10.0g                 ��Ͻ�������ۺϼ�������ҵ��ҵ��Ա�������ˣ�
a1317           double %10.0g                 ȫ�л��غ���������ҵ��Ա�������ˣ�
a1318           double %10.0g                 ��Ͻ�����غ���������ҵ��Ա�������ˣ�                                                > ?                                            > 
a1307           double %10.0g                 ȫ�е��ʿ��죬ˮ������ҵ��ҵ���������ˣ�
a1308           double %10.0g                 ��Ͻ�����ʿ��죬ˮ������ҵ��ҵ���������ˣ�
*/

/*use only data from 2003*/
keep if year>=2003
/*since obs for windustry is slightly larger than obs. for cindustry, use whole
city inudstry emp to compute Bartik index*/

keep city city_pinyin provc prov_cn year windustry*

order provc prov_cn city city_pinyin year windustry1-windustry19

sort provc prov_cn city city_pinyin year

reshape long windustry, i(provc prov_cn city city_pinyin year) j(inducode)

/*inducode: industry code
windustry: total employment of industry i*/

/*part 1: compute national, city level total employment, and their growth rates*/

/*generate national total employment for the whole country*/
sort year city inducode
by year: egen nationalemp=total(windustry)

/*growth rate of national employment*/
sort inducode city year
by inducode city: gen nationgrowth=(nationalemp-nationalemp[_n-1])/nationalemp[_n-1]

/*generate national total employment for each industry*/
sort inducode year city
by inducode year: egen nationalindemp=total(windustry)

/*generate growth rate of national employment by industry and by year*/
sort inducode city year
by inducode city: gen nationindgrowth=(nationalindemp-nationalindemp[_n-1])/nationalindemp[_n-1]
/*excluding industry emp in the city in question*/
by inducode city: gen nationindgrowth2=((nationalindemp-windustry) /// 
-(nationalindemp[_n-1]-windustry[_n-1]))/(nationalindemp[_n-1]-windustry[_n-1])


/*gen total city emp each year*/
sort city year inducode
by city year: egen cityemp=total(windustry)

/*gen share of city industry emp relative to city total emp*/
gen cityindshare=windustry/cityemp

/*gen lagged one year share of city industry emp relative to city total emp*/

sort city inducode year
gen cityindsharelag=cityindshare[_n-1]

/*part 2: gen predicted industry-city emp growth and compute bartik indexes*/
sort city year inducode

gen indcityempp1=cityindsharelag*(nationindgrowth)
/*simple weighted average: ind emp share in a city*national ind emp growth)*/

gen indcityempp2=cityindsharelag*(nationindgrowth2)
/*simple weighted average: ind emp share in a city*national ind emp growth,
but national ind emp growth excludes ind emp in a city*/

gen indcityempp3=cityindsharelag*(nationindgrowth-nationgrowth)
/*this is the term within the summation on page 194 of Saks(2008), but the 
national industry growth include industry emp in all cities*/

gen indcityempp4=cityindsharelag*(nationindgrowth2-nationgrowth)
/*this is the term within the summation on page 194 of Saks(2008), the 
national industry growth excludes industry emp in all cities*/

/*part 3: generate bartik index*/
/*generate the labor demand shock for each city*/
by city year: egen bartikindex1=total(indcityempp1)
by city year: egen bartikindex2=total(indcityempp2)
by city year: egen bartikindex3=total(indcityempp3)
by city year: egen bartikindex4=total(indcityempp4)

/*collaspe the bartik indexes by city year*/

sort city year
collapse (mean) bartikindex1 bartikindex2 bartikindex3 bartikindex4, by(city year)

/*
bartikindex1: weighted national industry growth, weights are industry emp share
in a city;

bartikindex2: weighted national industry growth, weights are industry emp share
in a city; national ind emp growth exclude ind emp in a particular city;


bartikindex3: weighted relative national industry growth, weights are industry emp share
in a city; relative national industry growth is national industry growth minus 
national emp growth;

bartikindex4: same as 2 but the national industry emp excludes ind emp of a particular
city, this is Saks' appendix formula*/

save bartikindex1234.dta, replace






