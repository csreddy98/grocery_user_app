import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:user_app/api/addressApi.dart';
import 'package:user_app/api/cartApi.dart';
import 'package:user_app/cart/address_search_map.dart';
import 'package:user_app/cart/cart_list.dart';
import 'package:user_app/main.dart';
import 'package:user_app/products/product_home_improved.dart';
import 'package:user_app/products/product_search.dart';
import 'package:user_app/products/wishlist_products.dart';
import 'package:user_app/services/constants.dart';
import 'package:user_app/utils/platform.dart';
import 'package:user_app/widgets/primaryButton.dart';
import 'package:user_app/widgets/text_widget.dart';

class DashboardTabs extends StatefulWidget {
  static final String tag = Constants.homeTag;
  final String page;
  DashboardTabs({this.page});
  @override
  _DashboardTabsState createState() => _DashboardTabsState();
}

class _DashboardTabsState extends State<DashboardTabs>
    with TickerProviderStateMixin {
  TabController _controller;
  List featured, sale, banners, categories;
  int cartCount = MyApp.cartList.isNotEmpty
      ? (MyApp.cartList['products'].length + MyApp.cartList['packs'].length)
      : 0;
  CartApiHandler cartHandler = new CartApiHandler();
  AddressApiHandler addressApi = AddressApiHandler();
  Map homeProducts = {};
  String displayAddress = MyApp.addresses != null && MyApp.addresses.length > 0
      ? MyApp.addresses[MyApp.selectedAddressId]['address']
      : "";
  List addresses;
  @override
  void initState() {
    _controller = new TabController(length: 3, vsync: this);
    if (widget.page == 'cart') {
      _controller.animateTo(1);
    }
    super.initState();
    if (MyApp.lat == null || MyApp.lng == null) {
      loadAddresses();
    } else {
      changeDisplayAddress(MyApp.selectedAddressId);
    }
    setState(() {});
  }

  changeDisplayAddress(int i) async {
    if (MyApp.addresses == null) {
      loadAddresses();
    } else {
      if (MyApp.addresses.length > 0) {
        print("selected Address: CHANGING ADDRESS FROM DASHBOARD TABS to $i");
        MyApp.setDefaultAddress(i);
        MyApp.lat = double.parse(MyApp.addresses[i]['lat']);
        MyApp.lng = double.parse(MyApp.addresses[i]['lng']);
        displayAddress = MyApp.addresses[i]['address'];
        homeProducts = await MyApp.loadHomePage(MyApp.lat, MyApp.lng);
        setState(() {});
      }
    }
  }

  loadAddresses() async {
    MyApp.selectedAddressId = await MyApp.getDefaultAddress();
    displayAddress = MyApp.addresses[MyApp.selectedAddressId]['address'];
    AddressApiHandler addressApiHandler = AddressApiHandler();
    List resp = await addressApiHandler.getAddresses();
    setState(() {
      MyApp.addresses = resp[1];
      displayAddress = MyApp.addresses[MyApp.selectedAddressId == -1
          ? 0
          : MyApp.selectedAddressId]['address'];
      MyApp.lat = double.parse(resp[1][MyApp.selectedAddressId]['lat']);
      MyApp.lng = double.parse(resp[1][MyApp.selectedAddressId]['lng']);
    });
  }

  loadCartCount() async {
    List getResp = await cartHandler.getCart();
    MyApp.cartList = getResp[1];
    cartCount = MyApp.cartList['products'] != null ||
            MyApp.cartList['packs'] != null
        ? (MyApp.cartList['products'].length + MyApp.cartList['packs'].length)
        : 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    loadCartCount();
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(builder: (context, setState) {
                      return Container(
                          height: size.height * 0.5,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  TextWidget("Pick your Address",
                                      textType: "heading"),
                                  SizedBox(height: 10),
                                  Divider(),
                                  SizedBox(height: 10),
                                  new Expanded(
                                    child: ListView.builder(
                                        itemCount: MyApp.addresses.length,
                                        itemBuilder: (_, i) {
                                          return ListTile(
                                              title: TextWidget("Other",
                                                  textType: "title"),
                                              subtitle: TextWidget(
                                                  MyApp.addresses[i]['address'],
                                                  textType: "para"),
                                              trailing: (MyApp
                                                          .addresses.length <=
                                                      1)
                                                  ? SizedBox()
                                                  : (MyApp.selectedAddressId ==
                                                          i)
                                                      ? SizedBox()
                                                      : IconButton(
                                                          icon: Icon(
                                                              Icons.delete,
                                                              color: Constants
                                                                  .dangerColor),
                                                          onPressed: () async {
                                                            var resp = await addressApi
                                                                .deleteAddress(
                                                                    MyApp.addresses[
                                                                            i]
                                                                        ['id']);
                                                            if (resp[0] ==
                                                                200) {
                                                              MyApp.addresses
                                                                  .removeAt(i);
                                                            }
                                                            setState(() {});
                                                          }),
                                              onTap: () async {
                                                changeDisplayAddress(i);
                                                homeProducts =
                                                    await MyApp.loadHomePage(
                                                        MyApp.addresses[i]
                                                            ['lat'],
                                                        MyApp.addresses[i]
                                                            ['lng']);
                                                setState(() {});
                                                Navigator.pop(context);
                                              });
                                        }),
                                  ),
                                  SizedBox(height: 5),
                                  Divider(),
                                  SizedBox(height: 5),
                                  PrimaryCustomButton(
                                      title: "Add New",
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    AddressSearchMap(
                                                        onSave:
                                                            DashboardTabs())));
                                      })
                                ]),
                          ));
                    });
                  });
            },
            child: Row(children: [
              Icon(Icons.location_pin),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextWidget("$displayAddress...", textType: "title"),
              )
            ]),
          ),
          actions: [
            Row(
              children: [
                IconButton(
                    icon: Icon(Ionicons.ios_search),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProductSearch()));
                    }),
              ],
            ),
          ]),
      drawer: PlatformState.getDrawer(context),
      body: Container(
        child: Column(
          children: [
            Container(
              child: new TabBar(
                controller: _controller,
                labelColor: Constants.iconColor,
                isScrollable: true,
                indicatorColor: Constants.iconColor,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Tab(
                      icon: Icon(
                        Entypo.shop,
                        color: Constants.iconColor,
                        size: size.height / 32,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Feather.shopping_cart,
                            color: Constants.iconColor,
                            size: size.height / 35,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Constants.primaryColor,
                                    borderRadius: BorderRadius.circular(15)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 5.0),
                                  child: Text("$cartCount",
                                      style: TextStyle(color: Colors.white)),
                                )),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Tab(
                      icon: Icon(
                        AntDesign.hearto,
                        color: Constants.iconColor,
                        size: size.height / 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                  child: new TabBarView(
                      controller: _controller,
                      children: <Widget>[
                    HomePageProducts(
                      homepageData: homeProducts,
                    ),
                    CartList(
                      onCountChange: (x) => setState(() {
                        cartCount = x;
                      }),
                    ),
                    WishListProducts(),
                  ])),
            )
          ],
        ),
      ),
    );
  }
}
