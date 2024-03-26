import "package:flutter/material.dart";
import "package:proxima/views/filter_widgets/timeline_filter/timeline_filters.dart";

/*
  This widget is the dropdown menu for the timeline filters.
*/
class TimeLineFiltersDropDown extends StatelessWidget {
  const TimeLineFiltersDropDown({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4.0,
      children: createFilterItems(context),
    );
  }

  List<ChoiceChip> createFilterItems(BuildContext context) {
    return TimeLineFilters.values.map((filter) {
      return ChoiceChip(
        //TODO: Handle the filter selection
        selected: filter.name == "Nearest",
        label: Text(filter.name),
      );
    }).toList();
  }
}
