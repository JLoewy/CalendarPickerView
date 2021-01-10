//
//  CalendarPicker.swift
//  JLCalendarPicker WatchKit Extension
//
//  Created by Jason Loewy on 1/6/21.
//

import SwiftUI

struct CalendarPickerView: View {
    
    private let todaysDate  = Date()
    private let todaysMonth = CalendarPickerView.Formatter.month.string(from: Date())
    
    let delegate:((DayNode) -> Void)
    
    @State private var activeDate: Date
    @State private var currentMonth: String
    @State private var currentCalendar = [[CalendarPickerView.DayNode]]()
    
    init(withActiveDate activeDate: Date, dateTappedBlock: @escaping ((DayNode) -> Void)) {
        self.delegate         = dateTappedBlock
        self._activeDate      = State(initialValue: activeDate)
        self._currentMonth    = State(initialValue: CalendarPickerView.Formatter.monthYear.string(from: activeDate))
        self._currentCalendar = State(initialValue: getCalendarMonth(withStartDate: activeDate))
    }
    
    var body: some View {
        
        VStack {
            HStack {
                Button(action: {
                    self.traverseDate(monthDelta: -1)
                }, label: {
                    Image(systemName: "chevron.left.circle")
                })
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text(self.currentMonth)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                Spacer()
                Button(action: {
                    self.traverseDate(monthDelta: 1)
                }, label: {
                    Image(systemName: "chevron.right.circle")
                })
                .buttonStyle(PlainButtonStyle())
            }
            Spacer(minLength: 8)
            ScrollView {
                VStack {
                    
                    VStack{
                        ForEach(self.currentCalendar, id: \.self) { currentRow in
                            HStack {
                                ForEach(currentRow, id: \.self) { currentDayNode in
                                    Button {
                                        self.delegate(currentDayNode)
                                        
                                    } label: {
                                        Text("\(currentDayNode.day)").font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 26, alignment: .center)
                                    .background(background(forNode: currentDayNode).cornerRadius(13))
                                    
                                }
                            }
                            Spacer(minLength: 4)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Date Mutators
    
    /// Get the 2D array of DayNodes that should be used to feed the Calendars display
    ///
    /// - Parameter startDate: **Date** the date whos month will be the month displayed
    ///
    /// - Returns: **[[CalendarPickerView.DayNode]]**
    private func getCalendarMonth(withStartDate startDate: Date) -> [[CalendarPickerView.DayNode]] {
        
        // Get the start of the month date
        let startComponents  = Calendar.current.dateComponents([.year, .month], from: startDate)
        let startOfMonthDate = Calendar.current.date(from: startComponents)!
        let startDayOfWeek   = Calendar.current.component(.weekday, from: startOfMonthDate)
        
        // This is the first date that will appear in the calender and what will be worked up as the container is filled
        var workingDate = Calendar.current.date(byAdding: .day, value: -(startDayOfWeek - 1), to: startOfMonthDate)!
        
        var tempCurrentCalendar = [[DayNode]]()
        tempCurrentCalendar.append([DayNode]())
        repeat {
            
            var currentRow = (tempCurrentCalendar.count - 1)
            if tempCurrentCalendar[currentRow].count == 7 {
                tempCurrentCalendar.append([DayNode]())
                currentRow += 1
            }
            
            let workingComponents = CalendarPickerView.Formatter.monthDay.string(from: workingDate).components(separatedBy: " ")
            let workingMonth = workingComponents[0]
            let workingDay   = Int(workingComponents[1])!
            let workingNode  = DayNode(date: workingDate, day: workingDay, outsideCurrentMonth: (workingMonth != todaysMonth))
            
            // Add the working node and traverse to the next date
            tempCurrentCalendar[currentRow].append(workingNode)
            workingDate.addTimeInterval(TimeInterval.day)
            
        } while tempCurrentCalendar.count < 6 || tempCurrentCalendar[5].count != 7
 
        // Make sure that the last row of the current calendar is not all not part of this month
        if tempCurrentCalendar.last?.firstIndex(where: { Calendar.current.component(.month, from: $0.date) == startComponents.month! }) == nil {
            tempCurrentCalendar.removeLast()
        }
        
        return tempCurrentCalendar
    }
    
    
    /// Change the showing date of the calendar
    ///
    /// - Parameter monthDelta: **Int** the delta from the current month that you want to change
    private func traverseDate(monthDelta: Int) {
        
        var deltaComponents   = DateComponents()
        deltaComponents.month = monthDelta
        
        if let newActiveDate = Calendar.current.date(byAdding: deltaComponents, to: activeDate) {
            self.activeDate      = newActiveDate
            self.currentCalendar = self.getCalendarMonth(withStartDate: newActiveDate)
            self.currentMonth    = CalendarPickerView.Formatter.monthYear.string(from: newActiveDate)
        }
    }
}

// MARK: -
// MARK: - UI Accessors

extension CalendarPickerView {
    
    /// Get the background color for the current DayNode. This is
    /// determined based off of if it's today or if it's in the current month or not
    ///
    /// - Parameter targetNode: **DayNode** the node whos background is being determined
    ///
    /// - Returns: **Color**
    private func background(forNode targetNode: DayNode) -> Color {
        
        if Calendar.current.isDateInToday(targetNode.date) {
            return Color.Calendar.activeDay
        }
        else {
            return targetNode.outsideCurrentMonth ? Color.clear : Color(#colorLiteral(red: 0.133328855, green: 0.1333370209, blue: 0.1376118958, alpha: 1))
        }
    }
}

// MARK: -
// MARK: - DayNode

extension CalendarPickerView {
    
    /// This struct models each day in the current calendar
    struct DayNode: Hashable {
        let date: Date
        let day: Int
        
        let outsideCurrentMonth: Bool
    }
}

// MARK: -
// MARK: - Date Formatters

extension CalendarPickerView {
    
    struct Formatter {
        
        /// MMMM yyyy
        static let monthYear: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter
        }()
        
        /// MMMM
        static let month: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return formatter
        }()
        
        /// MMMM d
        static let monthDay: DateFormatter = {
            let monthDayFormatter = DateFormatter()
            monthDayFormatter.dateFormat = "MMMM d"
            return monthDayFormatter
        }()
        
    }
}


// MARK: -
// MARK: - Preview

struct CalendarPicker_Previews: PreviewProvider {
    static var previews: some View {
        CalendarPickerView(withActiveDate: Date(), dateTappedBlock: {
            print("Date Tapped: \($0)")
        })
        .previewDevice("Apple Watch Series 6 - 40mm")
    }
}
