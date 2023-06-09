import 'package:flutter/material.dart';
import 'package:textfield_tags/textfield_tags.dart';

class TagEditing extends StatelessWidget {
  const TagEditing({
    super.key,
    required TextfieldTagsController tagController,
  }) : _tagController = tagController;

  final TextfieldTagsController _tagController;

  @override
  Widget build(BuildContext context) {
    return TextFieldTags(
      textfieldTagsController: _tagController,
      textSeparators: const [' ', ','],
      letterCase: LetterCase.normal,
      initialTags: const ['no-tag'],
      validator: (String tag) {
        if (tag.startsWith("#")) {
          return 'Hayır, lütfen hayır. Küstüm  :(';
        } else if (_tagController.getTags!.contains(tag)) {
          return 'Aynısını yazdın, Anam cıldıracam haaa';
          // ignore: prefer_is_empty
        } else if (_tagController.getTags!.length >= 3) {
          return 'Napıyon gebeş gablumbaga, 3 tane yeter';
        }
        return null;
      },
      inputfieldBuilder: (context, tec, fn, error, onChanged, onSubmitted) {
        return ((context, sc, tags, onTagDelete) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: tec,
              focusNode: fn,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 11, 0, 165),
                    width: 3.0,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 11, 0, 165),
                    width: 3.0,
                  ),
                ),
                helperStyle: const TextStyle(
                  color: Color.fromARGB(255, 245, 0, 0),
                ),
                hintText: _tagController.hasTags ? '' : "Enter tag...",
                errorText: error,
                prefixIcon: tags.isNotEmpty
                    ? SingleChildScrollView(
                        controller: sc,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: tags.map((String tag) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                              color: Colors.blueAccent.shade200,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {},
                                ),
                                const SizedBox(width: 14.0),
                                InkWell(
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 18.0,
                                    color: Color.fromARGB(255, 233, 233, 233),
                                  ),
                                  onTap: () {
                                    onTagDelete(tag);
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList()),
                      )
                    : null,
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          );
        });
      },
    );
  }
}
