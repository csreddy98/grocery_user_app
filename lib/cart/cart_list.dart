import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:user_app/api/cartApi.dart';
import 'package:user_app/cart/checkout_address.dart';
import 'package:user_app/main.dart';
import 'package:user_app/services/constants.dart';
import 'package:user_app/widgets/primaryButton.dart';
import 'package:user_app/widgets/cart_card.dart';
import 'package:user_app/widgets/text_widget.dart';

class CartList extends StatefulWidget {
  @override
  _CartListState createState() => _CartListState();
}

class _CartListState extends State<CartList> {
  CartApiHandler cartHandler = new CartApiHandler();
  double subtotal = 0;
  double delivery = 0;
  double tax = 0;
  double total = 0;
  List packs = [];

  @override
  void initState() {
    if (MyApp.cartList['products'] != null || MyApp.cartList['packs'] != null) {
      loadPrice();
    }
    super.initState();
  }

  void loadPrice() async {
    subtotal = 0;
    MyApp.cartList['products'].forEach((element) {
      subtotal += double.parse(element['offer_price'] != '0'
              ? element['offer_price']
              : element['price']) *
          int.parse(element['cartQuantity']);
    });
    // MyApp.cartList['packs'].forEach((element) {
    //   var jData = jsonDecode(element['pack_data']);
    //   subtotal += (double.parse(jData['PackPrice']) *
    //       int.parse(element['cartQuantity']));
    // });
    packs = MyApp.cartList['packs'];
    packs.forEach((element) {
      var jData = jsonDecode(element['pack_data']);
      subtotal += jData['OriginalPrice'] * int.parse(element['cartQuantity']);
      print("ELEMENT: $jData");
    });
    tax = (subtotal * 5).toInt() / 100;
    total = ((subtotal + tax + delivery) * 100).toInt() / 100;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          child: (MyApp.cartList['products'] == null &&
                      MyApp.cartList['packs'] == null) ||
                  (MyApp.cartList['products'].isEmpty &&
                      MyApp.cartList['packs'].isEmpty)
              ? Container(
                  height: size.height,
                  child: Center(
                    child: Text(
                      "Your cart is empty",
                      style: TextStyle(
                          fontSize: size.height / 50,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: MyApp.cartList['products'].length,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return CartCard(
                            name:
                                '${MyApp.cartList['products'][index]['product_name']}',
                            imgUrl: MyApp.cartList['products'][index]
                                        ['image_url'] !=
                                    null
                                ? MyApp.cartList['products'][index]['image_url']
                                    .toString()
                                    .replaceAll("http://", "https://")
                                : 'https://www.bigbasket.com/media/uploads/p/m/40023008_2-nestle-nesquik-chocolate-syrup-imported.jpg',
                            price:
                                '${MyApp.cartList['products'][index]['offer_price'] != '0' ? MyApp.cartList['products'][index]['offer_price'] : MyApp.cartList['products'][index]['price']}',
                            qty:
                                '${MyApp.cartList['products'][index]['quantity']} ${MyApp.cartList['products'][index]['metrics']}',
                            cartQuantity: MyApp.cartList['products'][index]
                                ['cartQuantity'],
                            productId: MyApp.cartList['products'][index]
                                ['product_pack_id'],
                            onDelete: (i) async {
                              print(MyApp.cartList['products'][index]
                                  ['product_id']);
                              List resp = await cartHandler.deleteFromCart(MyApp
                                  .cartList['products'][index]['product_id']);
                              print(resp[1]);
                              MyApp.showToast(resp[1]['message'], context);
                              if (resp[0] == 200) {
                                setState(() {
                                  MyApp.cartList['products'].removeAt(i);
                                });
                              }
                              loadPrice();
                            },
                            onQuantityChange: (val) async {
                              List resp = await cartHandler.updateCart({
                                "product_pack_id": MyApp.cartList['products']
                                    [index]['product_id'],
                                "quantity": val.toString()
                              });
                              if (resp[0] == 200) {
                                setState(() {
                                  MyApp.cartList['products'][index]
                                      ['cartQuantity'] = val.toString();
                                });
                              } else {
                                MyApp.showToast(resp[1]['message'], context);
                              }
                              loadPrice();
                            },
                          );
                        }),
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: packs.length,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          var jData = jsonDecode(
                              MyApp.cartList['packs'][0]['pack_data']);
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (_) {
                                    return StatefulBuilder(
                                        builder: (_, setState) {
                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: BackdropFilter(
                                                filter: new ImageFilter.blur(
                                                    sigmaX: 3, sigmaY: 3),
                                                child: Container(
                                                    color: Color(0x01000000))),
                                          ),
                                          Center(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: Container(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.8,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.8,
                                                  color: Colors.white),
                                            ),
                                          )
                                        ],
                                      );
                                    });
                                  });
                            },
                            child: CartCard(
                              name: '${packs[index]['pack_name']}',
                              imgUrl: packs[index]['pack_banner'] != null
                                  ? packs[index]['pack_banner']
                                      .toString()
                                      .replaceAll("http://", "https://")
                                  : 'https://www.bigbasket.com/media/uploads/p/m/40023008_2-nestle-nesquik-chocolate-syrup-imported.jpg',
                              price: '${jData['PackPrice']}',
                              cartQuantity: packs[index]['cartQuantity'],
                              productId: packs[index]['product_id'],
                              onDelete: (i) async {
                                List resp = await cartHandler.deleteFromCart(
                                    MyApp.cartList['packs'][index]['pack_id']);
                                MyApp.showToast(resp[1]['message'], context);
                                if (resp[0] == 200) {
                                  setState(() {
                                    MyApp.cartList['packs'].removeAt(i);
                                  });
                                }
                                loadPrice();
                              },
                              onQuantityChange: (val) async {
                                List resp = await cartHandler.updateCart({
                                  "product_pack_id": MyApp.cartList['packs']
                                      [index]['pack_id'],
                                  "quantity": val.toString()
                                });
                                if (resp[0] == 200) {
                                  setState(() {
                                    MyApp.cartList['packs'][index]
                                        ['cartQuantity'] = val.toString();
                                  });
                                } else {
                                  MyApp.showToast(resp[1]['message'], context);
                                }
                                loadPrice();
                              },
                            ),
                          );
                        }),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.22,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidget(
                                      'Sub Total',
                                      textType: "para",
                                    ),
                                    TextWidget(
                                      '₹ ' + subtotal.toString(),
                                      textType: "para-bold",
                                    )
                                  ]),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidget(
                                      'Delivery',
                                      textType: "para",
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    TextWidget(
                                      '₹ ' + delivery.toString(),
                                      textType: "para-bold",
                                    )
                                  ]),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidget(
                                      'Service Tax',
                                      textType: "para",
                                    ),
                                    TextWidget(
                                      '₹ ' + tax.toString(),
                                      textType: "para-bold",
                                    )
                                  ]),
                            ),
                            Divider(),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidget(
                                      'Total',
                                      textType: "para-bold",
                                    ),
                                    Text(
                                      '₹ ' + total.toString(),
                                      style: TextStyle(
                                          color: Constants.headingTextBlack,
                                          letterSpacing: 0.5,
                                          fontSize: size.height / 45,
                                          fontWeight: FontWeight.w600),
                                    )
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    PrimaryCustomButton(
                      title: 'CHECKOUT',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CheckoutAddress())),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
