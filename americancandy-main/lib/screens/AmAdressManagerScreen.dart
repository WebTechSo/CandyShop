import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/screens/AmAddNewAddress.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/data/services/address_service.dart';

class AmAddressManagerScreen extends StatefulWidget {
  static String tag = '/AddressManagerScreen';

  @override
  AmAddressManagerScreenState createState() => AmAddressManagerScreenState();
}

class AmAddressManagerScreenState extends State<AmAddressManagerScreen> {
  int? selectedAddressId;

  @override
  void initState() {
    super.initState();
  }

  deleteAddress(AmAddressModel model) async {
    if (model.id != null) {
      await AddressService().deleteAddress(model.id!);
      toasty(context, "Address deleted");
    }
  }

  editAddress(AmAddressModel model) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => AmAddNewAddress(
                  addressModel: model,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
              color: appStore.isDarkModeOn ? white : blackColor,
              icon: Icon(Icons.add),
              onPressed: () async {
                await AmAddNewAddress().launch(context);
              })
        ],
        actionsIconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        title: Text(sh_lbl_address_manager, style: boldTextStyle(size: 18)),
      ),
      body: StreamBuilder<List<AmAddressModel>>(
          stream: AddressService().getUserAddresses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No addresses found"));
            }

            List<AmAddressModel> addressList = snapshot.data!;

            // Determine effective selection for UI
            int? effectiveId = selectedAddressId;
            if (effectiveId == null && addressList.isNotEmpty) {
              // Try to find default address
              try {
                var defaultAddr = addressList.firstWhere(
                    (a) => a.default_address == true,
                    orElse: () => addressList[0]);
                effectiveId = defaultAddr.id;
              } catch (e) {
                effectiveId = addressList[0].id;
              }
            }

            return Stack(
              alignment: Alignment.bottomLeft,
              children: <Widget>[
                ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                      top: spacing_standard_new,
                      bottom: spacing_standard_new + 60),
                  itemBuilder: (item, index) {
                    var address = addressList[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: spacing_standard_new),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: ScrollMotion(),
                          children: [
                            SlidableAction(
                              icon: Icons.edit,
                              label: 'Edit',
                              backgroundColor: Colors.green,
                              flex: 1,
                              onPressed: (context) => editAddress(address),
                            ),
                            SlidableAction(
                              label: 'Delete',
                              backgroundColor: Colors.redAccent,
                              icon: Icons.delete_outline,
                              flex: 1,
                              onPressed: (context) => deleteAddress(address),
                            )
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedAddressId = address.id;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(spacing_standard_new),
                            margin: EdgeInsets.only(
                              right: spacing_standard_new,
                              left: spacing_standard_new,
                            ),
                            color: context.cardColor,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Radio<int>(
                                    value: address.id ?? -1,
                                    groupValue: effectiveId,
                                    onChanged: (int? value) {
                                      setState(() {
                                        selectedAddressId = value;
                                      });
                                    },
                                    activeColor: sh_colorPrimary),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(address.full_name!,
                                          style: boldTextStyle()),
                                      Text(address.address!,
                                          style: primaryTextStyle()),
                                      Text(address.city! + "," + address.state!,
                                          style: secondaryTextStyle()),
                                      Text(
                                          address.country! +
                                              "," +
                                              address.zip_code!,
                                          style: secondaryTextStyle()),
                                      16.height,
                                      Text(address.phone.toString(),
                                          style: primaryTextStyle()),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: sh_textColorSecondary),
                                  onPressed: () {
                                    editAddress(address);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  shrinkWrap: true,
                  itemCount: addressList.length,
                ),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    color: sh_colorPrimary,
                    elevation: 0,
                    padding: EdgeInsets.all(spacing_standard_new),
                    child: text("Save",
                        textColor: sh_white,
                        fontFamily: fontMedium,
                        fontSize: textSizeLargeMedium),
                    onPressed: () async {
                      int? idToSave = selectedAddressId;
                      // Fallback if user didn't select anything but default exists
                      if (idToSave == null && addressList.isNotEmpty) {
                        var def = addressList.firstWhere(
                            (a) => a.default_address == true,
                            orElse: () => addressList[0]);
                        idToSave = def.id;
                      }

                      if (idToSave != null) {
                        await AddressService().setDefaultAddress(idToSave);
                        toasty(context, "Default address saved");
                        Navigator.pop(context, idToSave);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                )
              ],
            );
          }),
    );
  }
}
