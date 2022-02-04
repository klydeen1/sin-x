//
//  sin_x_Calculator.swift
//  sin(x)
//
//  Created by Katelyn Lydeen on 2/3/22.
//  Based on code created by Jeff Terry on 12/29/20.
//

import Foundation
import SwiftUI
import CorePlot

// Create aliases that make it easier to pass in inputs as parameters.
typealias nthTermParameterTuple = (n: Int, x: Double)
typealias nthTermMultiplierHandler = (_ parameters: [nthTermParameterTuple]) -> Double
typealias ErrorHandler = (_ parameters: [ErrorParameterTuple]) -> Double
typealias ErrorParameterTuple = (n: Int, x: Double, sum: Double)

class Sin_X_Calculator: ObservableObject {
    
    var plotDataModel: PlotDataClass? = nil
    var plotError: Bool = false
    
    
    
    /// calculate_sin_x
    /// - Parameter x: values of x in sin(x)
    /// - Returns: sin(x)
    /// This function limits the range of x to the first period of -π to π
    /// It calculates the value of the sine using a Taylor Series Expansion of sin(x)
    ///
    ///                   N                   2n-1
    ///                   __            n-1  x
    ///    sin (x)  =    \        ( - 1)    -------
    ///                  /__                (2n-1)!
    ///                  n = 1
    ///
    func calculate_sin_x(x: Double) -> Double{
        
        // var sinXminusOne = 0.0
        var sinX = 0.0
        
        
        // If x is above pi, reduce it down until it is not (uses the periodicity of sin(x))
        var xInRange = x
        /*
        if (xInRange > Double.pi) {
        
            repeat {
                      xInRange -= 2.0*Double.pi
            } while xInRange > Double.pi
        
        }
        else if (xInRange < -Double.pi){
        
            repeat {
                      xInRange += 2.0*Double.pi
            } while xInRange < -Double.pi
        
        }
         */
        
        
        let firstTerm = xInRange // Term where n = 1
        
        plotDataModel!.zeroData()
        
        
        if !plotError  {
            
            //set the Plot Parameters
            plotDataModel!.changingPlotParameters.yMax = 1.5
            plotDataModel!.changingPlotParameters.yMin = -1.5
            plotDataModel!.changingPlotParameters.xMax = 15.0
            plotDataModel!.changingPlotParameters.xMin = -1.0
            plotDataModel!.changingPlotParameters.xLabel = "n"
            plotDataModel!.changingPlotParameters.yLabel = "sin(x)"
            plotDataModel!.changingPlotParameters.lineColor = .red()
            plotDataModel!.changingPlotParameters.title = "sin(x) vs n"
            
            // Plot first point of sin
            let dataPoint: plotDataType = [.X: 0.0, .Y: (1.0)]
            plotDataModel!.appendData(dataPoint: [dataPoint])
        }
        else {
        
            //set the Plot Parameters
            plotDataModel!.changingPlotParameters.yMax = 18.0
            plotDataModel!.changingPlotParameters.yMin = -18.1
            plotDataModel!.changingPlotParameters.xMax = 15.0
            plotDataModel!.changingPlotParameters.xMin = -1.0
            plotDataModel!.changingPlotParameters.xLabel = "n"
            plotDataModel!.changingPlotParameters.yLabel = "log(abs(Error))"
            plotDataModel!.changingPlotParameters.lineColor = .red()
            plotDataModel!.changingPlotParameters.title = "Error sin(x) vs n"
                
            var error = 0.0
            
            let actualsin_x = sin(x)
            
            if(actualsin_x != 0.0){
                
                var numerator = firstTerm - actualsin_x
                
                if(numerator == 0.0) {numerator = 1.0E-16}
                
                error = (log10(abs((numerator)/actualsin_x)))
                //error = (abs((numerator)/actualsin_x))
            }
            else {
                error = 0.0
            }
            
            // Plot first point of error
           
            let dataPoint: plotDataType = [.X: 0.0, .Y: (error)]
            plotDataModel!.appendData(dataPoint: [dataPoint])
            
        }
        
        // Calculate the infinite sum using the function that calculates the nth term in the series.
        
        sinX = calculate1DFiniteSum(function: sinnthTerm, x: xInRange, minimum: 1, maximum: 100, firstTerm: firstTerm, isPlotError: plotError, errorType: sinErrorCalculator  )
        
        return (sinX)
    }
    
    /// calculate1DFiniteSum
    /// - Parameters:
    ///   - function: function describing the nth term multiplier in the expansion
    ///   - x: value to be calculated
    ///   - minimum: minimum term in the sum usually 0 or 1
    ///   - maximum: maximum value of n in the expansion. Basically prevents an infinite loop
    ///   - firstTerm: First term in the expansion usually the value of the sum at the minimum
    ///   - isPlotError: boolean that describes whether to plot the value of the sum or the error with respect to a known value
    ///   - errorType: function used to calculate the log of the error when the exact value is known
    /// - Returns: the value of the infite sum
    func calculate1DFiniteSum(function: nthTermMultiplierHandler, x: Double, minimum: Int, maximum: Int, firstTerm: Double, isPlotError: Bool, errorType: ErrorHandler ) -> Double {
        
        
        var plotData :[plotDataType] =  []

        var sum = 0.0
        var previousTerm = firstTerm
        var currentTerm = 0.0
        let lowerIndex = minimum + 1
        
        if isPlotError {
            
            let errorParameters: [ErrorParameterTuple] = [(n: 1, x: x, sum: previousTerm)]
            
            let error = errorType(errorParameters)
            let dataPoint: plotDataType = [.X: Double(1), .Y: (error)]
            plotData.append(contentsOf: [dataPoint])
            
            
        }
        else{
            
            let dataPoint: plotDataType = [.X: Double(minimum), .Y: (previousTerm)]
            plotData.append(contentsOf: [dataPoint])
            
            print("n is \(minimum), x is \(x), currentTerm = \(previousTerm + 1.0)")
            
        }
        
        sum += firstTerm

        for n in lowerIndex...maximum {
        
            let parameters: [nthTermParameterTuple] = [(n: n, x: x)]
            
            // Calculate the infinite sum using the function that calculates the multiplier of the nth them in the series from the (n-1)th term.
        
            currentTerm = function(parameters)
            
            print("n is \(n), x is \(x), currentTerm = \(currentTerm)")
            sum += currentTerm
            
            print("The current ulp of sum is \(sum.ulp)")
            
            previousTerm = currentTerm
            
            if !isPlotError{
                
                let dataPoint: plotDataType = [.X: Double(n), .Y: (sum)]
                plotData.append(contentsOf: [dataPoint])
            }
            else{
                
                let errorParameters: [ErrorParameterTuple] = [(n: n, x: x, sum: sum)]
                
                let error = errorType(errorParameters)
                let dataPoint: plotDataType = [.X: Double(n), .Y: (error)]
                plotData.append(contentsOf: [dataPoint])
                
            }
            
            // Stop the summation when the current term is within machine precision of the total sum.
            
            if (abs(currentTerm) < sum.ulp){
                break
            }
    }
        plotDataModel!.appendData(dataPoint: plotData)
        return sum
    }
    
    /// sinnthTerm
    /// - Parameter parameters: Tuple containing the value of x and n
    /// - Returns: nth term multiplier (first term on the right side of the equation below)
    ///
    //                                 2n-1
    //      th                 n-1    x
    //    n    term  =  ( - 1)     ---------
    //                              (2n-1)!
    //
    ///
    
    func sinnthTerm(parameters: [nthTermParameterTuple])-> Double{
        var nthTerm = 0.0
        let n = Double(parameters[0].n)
        let x = parameters[0].x
        
        let denominator = factorial(n: 2*Int(n) - 1)
        
        nthTerm =  (-1.0)↑(n - 1) / (denominator) * (x↑(2.0*n - 1))
        
        return (nthTerm)
        
    }
    
    /// factorial
    /// Simple function to calculate the factorial of a number
    ///  - Parameter n: the number to find the factorial of
    ///  - Returns: the factorial of n
    func factorial(n: Int) -> Double {
      return (1...n).map(Double.init).reduce(1.0, *)
    }
    
    /// sinErrorCalculator
    /// - Parameter parameters: Tuple containing the parameters necessary to calculate the error form the true value of the function
    /// - Returns: log10(error) This is effectively the negative of the number of digits to which the calculation is "true."
    func sinErrorCalculator(parameters: [ErrorParameterTuple])-> Double{
        
        var error = 0.0
        _ = Double(parameters[0].n)
        let x = parameters[0].x
        let sum = parameters[0].sum
        
        let actualsin_x = sin(x)
        
        if(actualsin_x != 0.0){
            
            var numerator = sum - actualsin_x
            
            if(numerator == 0.0) {numerator = sum.ulp}
            
            error = (log10(abs((numerator)/actualsin_x)))
            
            
        }
        else {
            error = 0.0
        }
        
        return (error)
        
    }

}
