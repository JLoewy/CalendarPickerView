//
//  CalendarPicker.swift
//  JLCalendarPicker WatchKit Extension
//
//  Created by Jason Loewy on 1/6/21.
//

import SwiftUI


public struct CalendarPickerView: View {
    
    @Binding var showCalendar: Bool
    
    private let todaysDate  = Date()
    private let todaysMonth = CalendarPickerView.Formatter.month.string(from: Date())
    
    private let dayHeaders = ["S","M","T","W","T","F","S"]
    
    @Binding private var activeDate: Date
    
    @State private var currentMonth: String
    @State private var currentCalendar = [[CalendarPickerView.DayNode]]()
    
    var showJumpButtons: Bool
    
    public init(withActiveDate activeDate: Binding<Date>, showCalendar: Binding<Bool>, showJumpButtons: Bool) {
        
        self.showJumpButtons  = showJumpButtons
        self._showCalendar    = showCalendar
        self._activeDate      = activeDate
        
        self._currentMonth    = State(initialValue: CalendarPickerView.Formatter.monthYear.string(from: activeDate.wrappedValue))
        self._currentCalendar = State(initialValue: getCalendarMonth(withStartDate: activeDate.wrappedValue))
    }
    
    public var body: some View {
        
        NavigationView(content: {
            VStack {
                
                Spacer(minLength: 8)
                VStack {
                    
                    VStack{
                        // MARK: - Day of Week Header
                        HStack {
                            ForEach (dayHeaders, id: \.self) {
                                Text($0)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.9))
                                    .frame(minWidth: 0, maxWidth: .infinity)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.8))
                            .padding(.bottom, 1)
                        
                        ScrollView {
                            ForEach(self.currentCalendar, id: \.self) { currentRow in
                                HStack {
                                    // MARK: - Present Each Date Button
                                    ForEach(currentRow, id: \.self) { currentDayNode in
                                        Button {
                                            // MARK: - Date Selection & Dismissal
                                            self.activeDate   = currentDayNode.date
                                            self.showCalendar = false
                                        } label: {
                                            
                                            Text("\(currentDayNode.day)")
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundColor(textColor(forNode: currentDayNode))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 24, alignment: .center)
                                    }
                                }
                                Spacer(minLength: 4)
                            }
                            
                            if showJumpButtons {
                                VStack(spacing: 8) {
                                    Button(action: {
                                        self.activeDate   = Date()
                                        self.showCalendar = false
                                    }, label: {
                                        Text("Go To Today")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                    })
                                    
                                    Button(action: {
                                        self.showCalendar = false
                                    }, label: {
                                        Text("Cancel")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                    })
                                    
                                }.padding(.top, 16)
                                .padding([.leading, .trailing], 8)
                                
                            }
                        }
                        
                    }.gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded({ (g) in
                                
                                if g.translation.width > 0 {
                                    self.traverseDate(monthDelta: -1)
                                }
                                else {
                                    self.traverseDate(monthDelta: 1)
                                }
                                print("Gesture dragged: \(g.translation.width)")
                            })
                    )
                }
                
            }
        }).navigationTitle(self.currentMonth)
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
    
    /// Get the text color for the current DayNode. This is
    /// determined based off of if it's today or if it's in the current month or not
    ///
    /// - Parameter targetNode: **DayNode** the node whos text color is being determined
    ///
    /// - Returns: **Color**
    private func textColor(forNode targetNode: DayNode) -> Color {
        
        if Calendar.current.isDateInToday(targetNode.date) {
            return Color(#colorLiteral(red: 0.8235294118, green: 0.1843137255, blue: 0.1254901961, alpha: 1))
        }
        else {
            return targetNode.outsideCurrentMonth ? Color.white.opacity(0.5) : Color.white
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
    
    @State static var activeDate = Date()
    @State static var showingSheet = true
    
    static var previews: some View {
        CalendarPickerView(
            withActiveDate: CalendarPicker_Previews.$activeDate,
            showCalendar: CalendarPicker_Previews.$showingSheet,
            showJumpButtons: true
        )
        .previewDevice("Apple Watch Series 6 - 40mm")
    }
}
