// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export type AppName = 'mobile' | 'desktop'
export type AppSpecificRecord<T> = Record<AppName, T>
