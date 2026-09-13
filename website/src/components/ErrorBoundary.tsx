import { Component, type ErrorInfo, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRightIcon } from '../components/Icons'

interface Props {
  children: ReactNode
}
interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }
  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught:', error, errorInfo)
  }
  render() {
    if (this.state.hasError) {
      return (
        <div className="wrap py-20 text-center min-h-[60vh] flex flex-col items-center justify-center">
          <h1 className="hero-title mb-4">Something went wrong</h1>
          <p className="text-muted mb-8 max-w-lg">
            {this.state.error?.message || 'An unexpected error occurred.'}
          </p>
          <Link to="/" className="shop-button inline-flex">
            Go home <ArrowRightIcon />
          </Link>
        </div>
      )
    }
    return this.props.children
  }
}
