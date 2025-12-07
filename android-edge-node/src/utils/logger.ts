export class Logger {
    private prefix: string;

    constructor(prefix: string = 'EdgeNode') {
        this.prefix = prefix;
    }

    info(message: string, ...args: any[]) {
        console.log(`[${this.prefix}] [INFO]`, message, ...args);
    }

    success(message: string, ...args: any[]) {
        console.log(`[${this.prefix}] [SUCCESS]`, message, ...args);
    }

    error(message: string, ...args: any[]) {
        console.error(`[${this.prefix}] [ERROR]`, message, ...args);
    }

    warning(message: string, ...args: any[]) {
        console.warn(`[${this.prefix}] [WARNING]`, message, ...args);
    }

    debug(message: string, ...args: any[]) {
        if (import.meta.env.DEV) {
            console.debug(`[${this.prefix}] [DEBUG]`, message, ...args);
        }
    }
}






